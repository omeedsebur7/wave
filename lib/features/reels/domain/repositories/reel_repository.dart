import 'package:wave/core/utils/result.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';

abstract class ReelRepository {
  /// Cursor-based page fetch. Never reads the full collection (§6).
  Future<Result<ReelPage>> fetchFeed({Object? cursor, int limit});

  Future<Result<Reel>> fetchById(String reelId);

  /// Caption prefix search (§4). Same Firestore limitation as product search:
  /// prefix only, no fuzzy matching. Both move to a unified Algolia index in P2
  /// — the honest reason to migrate is that "shoes" cannot find "red shoes".
  Future<Result<List<Reel>>> search(String query, {int limit});

  Future<Result<List<Reel>>> byAuthor(String authorId, {int limit});

  /// Optimistic on the client, sharded on the server.
  Future<Result<void>> like(String reelId);
  Future<Result<void>> unlike(String reelId);

  Future<Result<void>> recordView(String reelId);
  Future<Result<void>> toggleSave(String reelId, {required bool saved});

  /// Exact like count, for the seller dashboard. The feed deliberately uses
  /// the cheaper materialised field.
  Future<Result<int>> exactLikeCount(String reelId);
}
