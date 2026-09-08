import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:wave/core/config/remote_config_keys.dart';
import 'package:wave/core/services/remote_config_service.dart';

/// Distributed counters for likes and views (§6 — Reels Feed Performance).
///
/// A single Firestore document sustains roughly one write per second. A Reel
/// that goes viral blows through that instantly, and the writes don't fail
/// loudly — they queue, slow down, and eventually error, which looks like "the
/// like button is broken" rather than "you hit a write limit".
///
/// So the count is never a field on the Reel document. It's spread across N
/// shard sub-documents; a like increments one at random. Reads take the
/// aggregation SUM query, and a scheduled Cloud Function materialises the total
/// back onto the parent doc so list views can render a count without N reads.

class ShardedCounterService {
  ShardedCounterService(this._config);

  
  final RemoteConfigService _config;
  final _random = Random();

  static const fallbackShardCount = 10;

  /// Live from Remote Config.
  ///
  /// Raising this raises throughput; lowering it lowers read cost. Both are
  /// things you only learn the right value for from production traffic, which
  /// is why it is tunable — but changing it does NOT lose existing counts,
  /// because the total is a sum across whatever shards exist.
  int get shardCount {
    final v = _config.getInt(RemoteConfigKeys.likeCounterShards);
    return v == 0 ? fallbackShardCount : v.clamp(1, 100);
  }

  CollectionReference<Map<String, dynamic>> _shards(
    DocumentReference<Map<String, dynamic>> parent,
    String counterName,
  ) =>
      parent.collection('counters_$counterName');

  /// Increment a random shard. Uses set(merge) + FieldValue.increment so the
  /// shard doc doesn't need to exist first — no read-before-write, no
  /// transaction, no contention.
  Future<void> increment(
    DocumentReference<Map<String, dynamic>> parent, {
    required String counterName,
    int by = 1,
    int? shards,
  }) async {
    final shardId = _random.nextInt(shards ?? shardCount).toString();
    await _shards(parent, counterName).doc(shardId).set(
      {'count': FieldValue.increment(by)},
      SetOptions(merge: true),
    );
  }

  /// Authoritative total via server-side aggregation — one billed read unit
  /// rather than N document reads.
  Future<int> total(
    DocumentReference<Map<String, dynamic>> parent, {
    required String counterName,
  }) async {
    final snap =
        await _shards(parent, counterName).aggregate(sum('count')).get();
    return (snap.getSum('count') ?? 0).toInt();
  }

  /// The cheap read path for feeds: the materialised field written by the
  /// scheduled function, falling back to 0 before the first materialisation.
  int materialised(
    Map<String, dynamic> parentData, {
    required String counterName,
  }) =>
      (parentData['${counterName}_count'] as num?)?.toInt() ?? 0;
}
