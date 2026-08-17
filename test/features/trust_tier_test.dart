import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

void main() {
  const t = TrustTierThresholds.fallback;

  group('Trust tier assignment (§5.2)', () {
    test('a brand-new seller has no badge', () {
      expect(
        t.tierFor(completedOrders: 0, avgRating: 0),
        TrustTier.newSeller,
      );
      expect(TrustTier.newSeller.hasBadge, isFalse);
    });

    test('9 perfect orders is still not Bronze — volume threshold is a floor', () {
      expect(
        t.tierFor(completedOrders: 9, avgRating: 5),
        TrustTier.newSeller,
      );
    });

    test('exactly at the threshold qualifies (>=, not >)', () {
      expect(
        t.tierFor(completedOrders: 10, avgRating: 4),
        TrustTier.bronze,
      );
    });

    test('high volume with a mediocre rating does NOT buy a tier', () {
      // The anti-gaming property that matters most: a seller cannot grind
      // their way to Platinum on volume alone.
      expect(
        t.tierFor(completedOrders: 5000, avgRating: 4.2),
        TrustTier.bronze,
      );
    });

    test('a perfect rating with low volume does not buy a tier either', () {
      expect(
        t.tierFor(completedOrders: 12, avgRating: 5),
        TrustTier.bronze,
      );
    });

    test('the highest qualifying tier wins', () {
      expect(
        t.tierFor(completedOrders: 600, avgRating: 4.9),
        TrustTier.platinum,
      );
      expect(
        t.tierFor(completedOrders: 600, avgRating: 4.65),
        TrustTier.gold,
      );
    });
  });
}
