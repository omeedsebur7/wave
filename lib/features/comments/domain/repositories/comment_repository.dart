import 'package:wave/core/utils/result.dart';
import 'package:wave/features/comments/domain/entities/comment.dart';

abstract class CommentRepository {
  /// Live, because a comment thread on an active Reel moves while it is open.
  Stream<List<Comment>> watch(String reelId, {int limit});

  /// Open to any signed-in non-guest user — NOT gated to purchasers.
  ///
  /// This is the deliberate deviation flagged in §0 of the brief. In a
  /// Reels-to-purchase funnel the highest-intent comments are pre-purchase
  /// questions, and restricting them to people who already bought removes
  /// exactly the discovery behaviour Buy Now depends on. Rate limiting plus
  /// report/block cover the downside.
  ///
  /// To revert to the stricter original ask: flip the
  /// `comments_verified_purchase_only` Remote Config flag and tighten the
  /// `comments` block in firestore.rules.
  Future<Result<void>> post({required String reelId, required String text});

  Future<Result<void>> delete({required String reelId, required String commentId});

  Future<Result<void>> toggleLike({
    required String reelId,
    required String commentId,
    required bool liked,
  });
}
