import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/config/remote_config_keys.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/services/block_list.dart';
import 'package:wave/core/services/remote_config_service.dart';
import 'package:wave/core/services/write_throttle.dart';
import 'package:wave/core/utils/rate_limiter.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/comments/domain/entities/comment.dart';
import 'package:wave/features/comments/domain/repositories/comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  CommentRepositoryImpl(
    this._db,
    this._auth,
    this._remoteConfig,
    this._throttle,
    this._blocks,
  );

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final RemoteConfigService _remoteConfig;

  /// Server-side cooldown (§4). The [_limiter] below is the client-side
  /// courtesy; this is the one Security Rules actually enforce, and it is what
  /// stops someone calling Firestore directly with a stolen token.
  final WriteThrottle _throttle;

  /// Blocking has to hide comments as well as Reels. A block that silenced
  /// someone's posts but left their replies under yours would be the more
  /// visible half of the problem left in place.
  final BlockList _blocks;

  /// Anti-abuse throttle (§4). The window comes from Remote Config so it can be
  /// tightened during an abuse wave without shipping a build.
  late final _limiter = RateLimiter(
    maxEvents: 5,
    window: Duration(
      seconds: _remoteConfig.getInt(RemoteConfigKeys.commentCooldownSeconds) * 5,
    ),
  );

  User? get _user => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> _comments(String reelId) =>
      _db.collection('reels').doc(reelId).collection('comments');

  @override
  Stream<List<Comment>> watch(String reelId, {int limit = 100}) {
    final uid = _user?.uid;

    return _comments(reelId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              // Blocking has to hide replies as well as posts. A block that
              // silenced someone's Reels but left their comments under yours
              // would leave the more visible half of the problem in place.
              if (!_blocks.isBlocked(doc.data()['author_id'] as String?))
                Comment(
                  id: doc.id,
                  reelId: reelId,
                  authorId: doc.data()['author_id'] as String? ?? '',
                  authorName: doc.data()['author_name'] as String? ?? '',
                  authorAvatarUrl: doc.data()['author_avatar_url'] as String?,
                  text: doc.data()['text'] as String? ?? '',
                  createdAt:
                      (doc.data()['created_at'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                  likeCount: (doc.data()['likes_count'] as num?)?.toInt() ?? 0,
                  likedByMe: uid != null &&
                      ((doc.data()['liked_by'] as List?) ?? []).contains(uid),
                  isFromSeller: doc.data()['is_from_seller'] as bool? ?? false,
                  // hasPendingWrites is the local echo of a write that has not
                  // reached the server — the offline queue, surfaced.
                  isPending: doc.metadata.hasPendingWrites,
                ),
          ],
        );
  }

  @override
  Future<Result<void>> post({
    required String reelId,
    required String text,
  }) async {
    final throttleWait = await _throttle.remaining(ThrottledWrite.comment);
    if (throttleWait != null) {
      return Err(RateLimitedFailure(
        'Comment write throttled',
        retryAfter: throttleWait,
        reason: FailureReason.commentingTooFast,
      ),);
    }

    final user = _user;
    if (user == null) {
      return const Err(
        AuthFailure(
          'Sign in to comment',
          reason: FailureReason.signInToComment,
        ),
      );
    }
    if (user.isAnonymous) {
      // Guests browse and buy nothing; commenting needs an identity that can
      // be reported and blocked.
      return const Err(
        AuthFailure(
          'Create an account to join the conversation',
          reason: FailureReason.guestCannotComment,
        ),
      );
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) return const Success(null);
    if (trimmed.length > 500) {
      return const Err(
        ServerFailure(
          'That comment is too long',
          reason: FailureReason.commentTooLong,
        ),
      );
    }

    // Server-side kill switch for the §0 decision. If this is ever flipped on,
    // the rule tightens without a client release.
    if (_remoteConfig
        .getBool(RemoteConfigKeys.commentsVerifiedPurchaseOnly)) {
      final eligible = await _hasPurchasedFromReel(reelId, user.uid);
      if (!eligible) {
        return const Err(
          PermissionFailure(
            'Comments on this Reel are limited to people who bought the item.',
            FailureReason.commentsBuyersOnly,
          ),
        );
      }
    }

    final limiterWait = _limiter.check(user.uid);
    if (limiterWait != null) {
      return Err(
        RateLimitedFailure(
          'Commenting rate limited',
          retryAfter: limiterWait,
          reason: FailureReason.commentingTooFast,
        ),
      );
    }

    try {
      final reel = await _db.collection('reels').doc(reelId).get();

      // Stamped first: the rule reads this document, and a write that skipped
      // the stamp would never be limited.
      await _throttle.stamp(ThrottledWrite.comment);

      await _comments(reelId).add({
        'author_id': user.uid,
        // Stored blank rather than as an English placeholder: a value written
        // here outlives every future translation of it.
        'author_name': user.displayName ?? '',
        'author_avatar_url': user.photoURL,
        'text': trimmed,
        'is_from_seller': reel.data()?['author_id'] == user.uid,
        'likes_count': 0,
        'liked_by': <String>[],
        'created_at': FieldValue.serverTimestamp(),
      });

      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(
        e.code == 'permission-denied'
            ? const PermissionFailure(
                'You cannot comment on this Reel',
                FailureReason.commentNotAllowed,
              )
            : ServerFailure(
                e.message ?? 'Could not post',
                code: e.code,
                reason: FailureReason.commentPostFailed,
              ),
      );
    }
  }

  @override
  Future<Result<void>> delete({
    required String reelId,
    required String commentId,
  }) async {
    try {
      await _comments(reelId).doc(commentId).delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(
        e.code == 'permission-denied'
            ? const PermissionFailure(
                'You can only delete your own comments',
                FailureReason.commentDeleteOwnOnly,
              )
            : ServerFailure(e.message ?? 'Error', code: e.code),
      );
    }
  }

  @override
  Future<Result<void>> toggleLike({
    required String reelId,
    required String commentId,
    required bool liked,
  }) async {
    final uid = _user?.uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Sign in first', reason: FailureReason.notSignedIn),
      );
    }

    try {
      // Comment likes stay a plain array rather than sharded counters: a single
      // comment is nowhere near the one-write-per-second ceiling that makes a
      // Reel's like count need sharding, and an array gives "did I like this?"
      // for free without a second read.
      await _comments(reelId).doc(commentId).update({
        'liked_by': liked
            ? FieldValue.arrayUnion([uid])
            : FieldValue.arrayRemove([uid]),
        'likes_count': FieldValue.increment(liked ? 1 : -1),
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  Future<bool> _hasPurchasedFromReel(String reelId, String uid) async {
    final reel = await _db.collection('reels').doc(reelId).get();
    final productId = reel.data()?['linked_product_id'] as String?;
    if (productId == null) return false;

    final orders = await _db
        .collection('orders')
        .where('buyer_id', isEqualTo: uid)
        .where('product_ids', arrayContains: productId)
        .where('status', isEqualTo: 'delivered')
        .limit(1)
        .get();

    return orders.docs.isNotEmpty;
  }
}