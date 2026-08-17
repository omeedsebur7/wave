import 'package:wave/core/error/failures.dart' show PermissionFailure;
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/reviews/domain/entities/review.dart';

/// Rating aggregate for a product: the average, the count, and the full
/// distribution. The distribution is fetched alongside the average because a
/// 4.0 made of all-4s and a 4.0 made of half-5s-half-3s are different products,
/// and showing only the mean hides that.
class RatingSummary {
  const RatingSummary({
    required this.average,
    required this.distribution,
  });

  static const empty = RatingSummary(average: 0, distribution: {});

  final double average;

  /// Star value (1–5) to count.
  final Map<int, int> distribution;

  int get total => distribution.values.fold(0, (a, b) => a + b);
}

abstract class ReviewRepository {
  Future<Result<List<Review>>> forProduct(String productId, {int limit});

  Future<Result<RatingSummary>> summaryForProduct(String productId);

  /// Fails with a [PermissionFailure] unless the caller has a delivered order
  /// containing this product. The same rule is enforced in Security Rules —
  /// this is the client-side half, so the user gets a clear message instead of
  /// a raw permission-denied.
  Future<Result<void>> submitProductReview({
    required String productId,
    required String orderId,
    required int rating,
    String? text,
  });

  /// Feeds the trust tiers (§5.2). One per completed order, keyed by orderId so
  /// a second submission is a write against an existing document rather than a
  /// duplicate.
  Future<Result<void>> submitSellerRating({
    required String sellerId,
    required String orderId,
    required int rating,
    String? text,
  });

  Future<Result<void>> editReview({
    required String reviewId,
    required int rating,
    String? text,
  });
}
