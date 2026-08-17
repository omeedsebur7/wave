import 'package:equatable/equatable.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

/// A seller as a buyer sees them.
///
/// Every field here is either evidence a stranger can check or a fact they can
/// act on. Nothing is self-declared except the bio — the tier, the rating, the
/// order count and the join date all come from completed transactions, which is
/// the entire reason the badge means anything.
class SellerProfile extends Equatable {
  const SellerProfile({
    required this.id,
    required this.displayName,
    required this.tier,
    required this.joinedAt,
    this.avatarUrl,
    this.bio,
    this.kycVerified = false,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.completedOrders = 0,
    this.followerCount = 0,
    this.productCount = 0,
    this.reelCount = 0,
    this.isFollowedByMe = false,
    this.isBlockedByMe = false,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? bio;

  final TrustTier tier;
  final bool kycVerified;

  final double avgRating;
  final int ratingCount;
  final int completedOrders;

  final DateTime joinedAt;
  final int followerCount;
  final int productCount;
  final int reelCount;

  final bool isFollowedByMe;
  final bool isBlockedByMe;

  bool get hasTrackRecord => completedOrders > 0;

  /// What a buyer needs to reach the NEXT tier's worth of confidence.
  ///
  /// Shown to the seller on their own profile as a concrete target, because
  /// "get more orders" is not actionable and "42 more orders at 4.3+" is.
  ({int orders, double rating})? progressTo(
    TrustTier next,
    TrustTierThresholds thresholds,
  ) {
    final (needOrders, needRating) = switch (next) {
      TrustTier.bronze => (thresholds.bronzeOrders, thresholds.bronzeRating),
      TrustTier.silver => (thresholds.silverOrders, thresholds.silverRating),
      TrustTier.gold => (thresholds.goldOrders, thresholds.goldRating),
      TrustTier.platinum =>
        (thresholds.platinumOrders, thresholds.platinumRating),
      TrustTier.newSeller => (0, 0.0),
    };
    if (needOrders == 0) return null;
    return (
      orders: (needOrders - completedOrders).clamp(0, needOrders),
      rating: needRating,
    );
  }

  @override
  List<Object?> get props =>
      [id, tier, avgRating, completedOrders, isFollowedByMe];
}
