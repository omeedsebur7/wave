import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/selling/domain/entities/seller_stats.dart';

void main() {
  group('Funnel rates', () {
    test('splits tap-through from completion', () {
      // The two halves fail for opposite reasons and need opposite fixes, so
      // they are reported separately rather than collapsed into one number.
      const stats = SellerStats(
        periodDays: 30,
        reelViews: 1000,
        buyNowTaps: 50,
        ordersPlaced: 10,
      );

      expect(stats.tapThroughRate, 0.05);
      expect(stats.tapToOrderRate, 0.2);
      expect(stats.overallConversion, 0.01);
    });

    test('returns zero rather than NaN when nothing has happened', () {
      // A NaN would render as "NaN%" on a new seller's first look at this
      // screen, which is the worst possible first impression.
      const empty = SellerStats(periodDays: 30);
      expect(empty.tapThroughRate, 0);
      expect(empty.tapToOrderRate, 0);
      expect(empty.overallConversion, 0);
    });

    test('handles taps with no views without dividing by zero', () {
      const odd = SellerStats(periodDays: 30, buyNowTaps: 5, ordersPlaced: 1);
      expect(odd.tapThroughRate, 0);
      expect(odd.tapToOrderRate, 0.2);
    });
  });

  group('Statistical honesty', () {
    test('flags a sample too small to draw conclusions from', () {
      // Showing "3% conversion" off 12 views invites a seller to change
      // something based on noise.
      expect(
        const SellerStats(periodDays: 30, reelViews: 99).hasEnoughDataToJudge,
        isFalse,
      );
      expect(
        const SellerStats(periodDays: 30, reelViews: 100).hasEnoughDataToJudge,
        isTrue,
      );
    });
  });

  group('Wasted audience detection', () {
    ReelPerformance reel({required int views, required bool linked}) =>
        ReelPerformance(
          reelId: 'r1',
          caption: 'c',
          thumbnailUrl: '',
          views: views,
          hasLinkedProduct: linked,
        );

    test('flags a well-watched Reel with nothing to buy', () {
      // The single most actionable finding: the audience already exists and
      // the fix is one tap.
      expect(reel(views: 500, linked: false).isWastedAudience, isTrue);
    });

    test('does not flag a Reel that already sells something', () {
      expect(reel(views: 5000, linked: true).isWastedAudience, isFalse);
    });

    test('does not flag a Reel nobody watched', () {
      // Telling someone to link a product to a Reel with 12 views is noise.
      expect(reel(views: 12, linked: false).isWastedAudience, isFalse);
    });
  });
}
