import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/profile/domain/entities/seller_profile.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

SellerProfile _seller({int orders = 0, double rating = 0}) => SellerProfile(
      id: 's1',
      displayName: 'Seller',
      tier: TrustTierThresholds.fallback
          .tierFor(completedOrders: orders, avgRating: rating),
      joinedAt: DateTime(2026),
      completedOrders: orders,
      avgRating: rating,
    );

void main() {
  const thresholds = TrustTierThresholds.fallback;

  group('Track record', () {
    test('a seller with no delivered orders has no track record', () {
      // Drives the honest "no completed orders yet" panel rather than a row of
      // zeros, which reads as a warning the data does not support.
      expect(_seller().hasTrackRecord, isFalse);
    });

    test('one delivered order counts', () {
      expect(_seller(orders: 1, rating: 5).hasTrackRecord, isTrue);
    });
  });

  group('Progress to the next tier', () {
    test('reports how many more orders are needed, and at what rating', () {
      final seller = _seller(orders: 8, rating: 4.5);
      final progress = seller.progressTo(TrustTier.bronze, thresholds);

      expect(progress, isNotNull);
      expect(progress!.orders, 2);
      expect(progress.rating, 4.0);
    });

    test('never reports a negative remainder once the bar is cleared', () {
      final seller = _seller(orders: 40, rating: 4.5);
      final progress = seller.progressTo(TrustTier.bronze, thresholds);
      expect(progress!.orders, 0);
    });

    test('newSeller is not a target to progress toward', () {
      expect(_seller().progressTo(TrustTier.newSeller, thresholds), isNull);
    });

    test('the tier on the profile matches the shared threshold logic', () {
      // Guards against the profile drifting from the badge shown elsewhere.
      expect(_seller(orders: 600, rating: 4.9).tier, TrustTier.platinum);
      expect(_seller(orders: 600, rating: 4.2).tier, TrustTier.bronze);
    });
  });
}
