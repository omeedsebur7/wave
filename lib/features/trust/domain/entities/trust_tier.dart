/// Seller trust tiers (§5.2 / §3.7).
///
/// Thresholds are NOT defined here — they live in Remote Config so they can be
/// tuned once real order volume exists, per the brief's explicit instruction
/// not to hardcode them. See [TrustTierThresholds].
enum TrustTier {
  /// Fewer than 10 completed orders. No badge — a neutral chip or nothing.
  newSeller,
  bronze,
  silver,
  gold,
  platinum;

  bool get hasBadge => this != TrustTier.newSeller;
}

/// Server-tunable thresholds, hydrated from Remote Config at startup.
class TrustTierThresholds {
  const TrustTierThresholds({
    required this.bronzeOrders,
    required this.bronzeRating,
    required this.silverOrders,
    required this.silverRating,
    required this.goldOrders,
    required this.goldRating,
    required this.platinumOrders,
    required this.platinumRating,
  });

  /// Matches the illustrative table in §5.2. Used only as a fallback if Remote
  /// Config hasn't fetched yet.
  static const fallback = TrustTierThresholds(
    bronzeOrders: 10,
    bronzeRating: 4,
    silverOrders: 50,
    silverRating: 4.3,
    goldOrders: 150,
    goldRating: 4.6,
    platinumOrders: 500,
    platinumRating: 4.8,
  );

  final int bronzeOrders;
  final double bronzeRating;
  final int silverOrders;
  final double silverRating;
  final int goldOrders;
  final double goldRating;
  final int platinumOrders;
  final double platinumRating;

  /// Both conditions must hold, and the highest qualifying tier wins. A seller
  /// with 600 orders at 4.2 stars is Bronze, not Platinum — volume alone never
  /// buys a tier.
  TrustTier tierFor({required int completedOrders, required double avgRating}) {
    if (completedOrders >= platinumOrders && avgRating >= platinumRating) {
      return TrustTier.platinum;
    }
    if (completedOrders >= goldOrders && avgRating >= goldRating) {
      return TrustTier.gold;
    }
    if (completedOrders >= silverOrders && avgRating >= silverRating) {
      return TrustTier.silver;
    }
    if (completedOrders >= bronzeOrders && avgRating >= bronzeRating) {
      return TrustTier.bronze;
    }
    return TrustTier.newSeller;
  }
}
