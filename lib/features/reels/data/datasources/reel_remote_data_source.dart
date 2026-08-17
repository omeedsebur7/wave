import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:wave/core/services/sharded_counter_service.dart';
import 'package:wave/features/reels/data/models/reel_dto.dart';

@lazySingleton
class ReelRemoteDataSource {
  ReelRemoteDataSource(this._db, this._counters);

  final FirebaseFirestore _db;
  final ShardedCounterService _counters;

  CollectionReference<Map<String, dynamic>> get _reels =>
      _db.collection('reels');

  /// Cursor pagination (§6). `startAfterDocument` + `limit` — a fixed page of
  /// 5–10, never the whole collection.
  ///
  /// Ordered by rankScore then createdAt. rankScore is written by a scheduled
  /// function, so the client does no ranking work; createdAt breaks ties and
  /// guarantees a stable cursor. Requires the composite index declared in
  /// firestore.indexes.json.
  Future<(List<ReelDto>, DocumentSnapshot<Map<String, dynamic>>?, bool)>
      fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? cursor,
    int limit = 8,
    String? currentUserId,
  }) async {
    var query = _reels
        .where('status', isEqualTo: 'published')
        .orderBy('rank_score', descending: true)
        .orderBy('created_at', descending: true)
        // Fetch one extra to detect hasMore without a second query.
        .limit(limit + 1);

    if (cursor != null) query = query.startAfterDocument(cursor);

    final snap = await query.get();
    final docs = snap.docs;
    final hasMore = docs.length > limit;
    final pageDocs = hasMore ? docs.sublist(0, limit) : docs;

    final dtos = pageDocs
        .map((d) => ReelDto.fromFirestore(d.id, d.data()))
        .toList();

    return (dtos, pageDocs.isEmpty ? null : pageDocs.last, hasMore);
  }

  /// Prefix search on a lowercased caption field written at publish time.
  Future<List<ReelDto>> searchByCaption(String term, {int limit = 20}) async {
    final snap = await _reels
        .where('status', isEqualTo: 'published')
        .orderBy('caption_lower')
        .startAt([term])
        .endAt(['$term\uf8ff'])
        .limit(limit)
        .get();

    return [
      for (final d in snap.docs) ReelDto.fromFirestore(d.id, d.data()),
    ];
  }

  Future<List<ReelDto>> byAuthor(String authorId, {int limit = 30}) async {
    final snap = await _reels
        .where('author_id', isEqualTo: authorId)
        .where('status', isEqualTo: 'published')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .get();

    return [
      for (final d in snap.docs) ReelDto.fromFirestore(d.id, d.data()),
    ];
  }

  Future<ReelDto?> fetchById(String reelId) async {
    final doc = await _reels.doc(reelId).get();
    final data = doc.data();
    if (data == null) return null;
    return ReelDto.fromFirestore(doc.id, data);
  }

  /// Likes are two writes: a membership doc (so "did I like this?" is a cheap
  /// point read and the rule can enforce one-like-per-user) and a sharded
  /// counter increment (so the aggregate survives virality).
  Future<void> setLike({
    required String reelId,
    required String userId,
    required bool liked,
  }) async {
    final reelRef = _reels.doc(reelId);
    final likeRef = reelRef.collection('likes').doc(userId);

    if (liked) {
      await likeRef.set({'created_at': FieldValue.serverTimestamp()});
      await _counters.increment(reelRef, counterName: 'likes');
    } else {
      await likeRef.delete();
      await _counters.increment(reelRef, counterName: 'likes', by: -1);
    }
  }

  Future<void> recordView({required String reelId, required String userId}) {
    // Views are fire-and-forget and always sharded — this is the single
    // highest-frequency write in the app.
    return _counters.increment(_reels.doc(reelId), counterName: 'views');
  }

  Future<void> toggleSave({
    required String reelId,
    required String userId,
    required bool saved,
  }) async {
    final ref =
        _db.collection('users').doc(userId).collection('saved_reels').doc(reelId);
    if (saved) {
      await ref.set({'created_at': FieldValue.serverTimestamp()});
    } else {
      await ref.delete();
    }
  }

  /// Authoritative like count, summed across shards.
  ///
  /// The feed reads the materialised field instead, which is up to one
  /// schedule interval stale — fine for a number nobody checks precisely. This
  /// exists for the places where "roughly right" is not good enough: a
  /// creator looking at their own Reel, and reconciliation.
  Future<int> authoritativeLikeCount(String reelId) =>
      _counters.total(_reels.doc(reelId), counterName: 'likes');

  Future<Set<String>> likedReelIds(String userId, List<String> reelIds) async {
    if (reelIds.isEmpty) return {};
    final results = await Future.wait(
      reelIds.map((id) => _reels.doc(id).collection('likes').doc(userId).get()),
    );
    return {
      for (var i = 0; i < results.length; i++)
        if (results[i].exists) reelIds[i],
    };
  }
}
