import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/services/write_throttle.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/profile/domain/entities/seller_profile.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

class SellerProfileRepository {
  SellerProfileRepository(this._db, this._auth, this._throttle);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final WriteThrottle _throttle;

  String? get _uid => _auth.currentUser?.uid;

  Future<Result<SellerProfile>> byId(String sellerId) async {
    try {
      final uid = _uid;

      // Profile, follow state and block state in parallel — three sequential
      // reads would show a follow button that flickers into the wrong state.
      //
      // Signed-out callers contribute no futures rather than placeholder ones.
      // The previous shape padded the list with `Future.value(null)` to keep
      // its length at three, which made the list heterogeneous and left the
      // element type resting entirely on that `null`. `dart fix` then removed
      // the `null` as a redundant argument value — correct in isolation — and
      // the element type collapsed to dynamic, taking every field read below
      // with it. Homogeneous, there is nothing left to infer wrongly.
      final results = await Future.wait([
        _db.collection('users').doc(sellerId).get(),
        if (uid != null) ...[
          _db
              .collection('users')
              .doc(uid)
              .collection('following')
              .doc(sellerId)
              .get(),
          _db
              .collection('blocks')
              .doc(uid)
              .collection('blocked')
              .doc(sellerId)
              .get(),
        ],
      ]);

      final doc = results[0];
      final data = doc.data();
      if (data == null) {
        return const Err(
          NotFoundFailure('Seller not found', FailureReason.sellerNotFound),
        );
      }

      // Guarded by the same condition that decided whether to request them, so
      // the indices cannot drift from the list above.
      final following = uid == null ? null : results[1];
      final blocked = uid == null ? null : results[2];

      return Success(
        SellerProfile(
          id: doc.id,
          displayName: data['display_name'] as String? ?? '',
          avatarUrl: data['photo_url'] as String?,
          bio: data['bio'] as String?,
          tier: TrustTier.values.firstWhere(
            (t) => t.name == data['trust_tier'],
            // An unknown tier from a newer backend shows no badge rather than
            // guessing. Showing nothing is always safe.
            orElse: () => TrustTier.newSeller,
          ),
          kycVerified: data['kyc_verified'] as bool? ?? false,
          avgRating: (data['avg_rating'] as num?)?.toDouble() ?? 0,
          ratingCount: (data['rating_count'] as num?)?.toInt() ?? 0,
          completedOrders: (data['completed_orders'] as num?)?.toInt() ?? 0,
          joinedAt:
              (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          followerCount: (data['follower_count'] as num?)?.toInt() ?? 0,
          productCount: (data['product_count'] as num?)?.toInt() ?? 0,
          reelCount: (data['reel_count'] as num?)?.toInt() ?? 0,
          isFollowedByMe: following?.exists ?? false,
          isBlockedByMe: blocked?.exists ?? false,
        ),
      );
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  Future<Result<void>> toggleFollow(
    String sellerId, {
    required bool follow,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Sign in to follow', reason: FailureReason.signInToFollow),
      );
    }
    if (uid == sellerId) {
      return const Err(
        ServerFailure(
          'You cannot follow yourself',
          reason: FailureReason.cannotFollowYourself,
        ),
      );
    }

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .doc(sellerId);

    // Only following is throttled. Unfollowing is not: making it harder to
    // withdraw attention than to give it is the wrong asymmetry, and someone
    // rate-limited out of unfollowing an account they want away from has a
    // worse problem than the one the limit solves.
    if (follow) {
      final wait = await _throttle.remaining(ThrottledWrite.follow);
      if (wait != null) {
        return Err(
          RateLimitedFailure(
            'Follow write throttled',
            retryAfter: wait,
            reason: FailureReason.followThrottled,
          ),
        );
      }
    }

    try {
      if (follow) {
        await _throttle.stamp(ThrottledWrite.follow);
        await ref.set({'created_at': FieldValue.serverTimestamp()});
      } else {
        await ref.delete();
      }
      // follower_count is materialised by a Cloud Function on this write, not
      // incremented here — a client that can set its own follower count is a
      // client that can fake reach.
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  Future<Result<void>> toggleBlock(
    String sellerId, {
    required bool blocked,
  }) async {
    final uid = _uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Sign in first', reason: FailureReason.notSignedIn),
      );
    }

    final ref = _db
        .collection('blocks')
        .doc(uid)
        .collection('blocked')
        .doc(sellerId);

    try {
      if (blocked) {
        await ref.set({'created_at': FieldValue.serverTimestamp()});
        // Blocking implies unfollowing. Leaving a follow in place would keep
        // their Reels in the ranked feed's follow boost, which is not what
        // anyone means by "block".
        await _db
            .collection('users')
            .doc(uid)
            .collection('following')
            .doc(sellerId)
            .delete();
      } else {
        await ref.delete();
      }
      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }
}