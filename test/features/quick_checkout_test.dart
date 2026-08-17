import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/checkout/domain/entities/checkout_gate.dart';
import 'package:wave/features/checkout/presentation/bloc/quick_checkout_cubit.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

/// State logic for the Buy Now sheet.
///
/// This screen shipped as hardcoded placeholder data for several passes — a grey
/// box for the image, a fixed trust tier, an invented buyer count, and a Buy Now
/// button whose callback was a comment. It looked complete in review because
/// every individual line was plausible.
///
/// These tests pin the decisions the sheet actually has to make, so the next
/// version of that mistake fails loudly.

/// Fixed rather than `DateTime.now()`. Nothing here reads the value, and a
/// moving clock in a fixture is a flake waiting for a boundary or a timezone.
final _createdAt = DateTime.utc(2024);

void main() {
  Product product({int stock = 10, int soldCount = 0}) => Product(
        id: 'p1',
        sellerId: 's1',
        sellerName: 'Test Seller',
        title: 'A thing',
        description: '',
        priceMinor: 25000,
        currency: 'IQD',
        stock: stock,
        imageUrls: const ['https://example.test/a.jpg'],
        soldCount: soldCount,
        sellerTier: TrustTier.gold,
        createdAt: _createdAt,
      );

  const ready = CheckoutReadiness(
    isGuest: false,
    hasVerifiedPhone: true,
    hasSavedAddress: true,
    hasPaymentMethod: true,
  );

  group('Purchasability', () {
    test('a stocked product with a ready buyer is purchasable', () {
      final state = QuickCheckoutState(
        status: QuickCheckoutStatus.ready,
        product: product(),
        readiness: ready,
      );
      expect(state.isPurchasable, isTrue);
      expect(state.gate, CheckoutGate.ready);
    });

    test('a sold-out product is not purchasable', () {
      // Between the feed loading and the tap, the last one can go.
      final state = QuickCheckoutState(
        status: QuickCheckoutStatus.ready,
        product: product(stock: 0),
        readiness: ready,
      );
      expect(state.isPurchasable, isFalse);
    });

    test('nothing is purchasable while an order is being placed', () {
      // Guards the double tap. The idempotency key would deduplicate it
      // server-side anyway, but not sending the second request is better than
      // relying on the server to discard it.
      final state = QuickCheckoutState(
        status: QuickCheckoutStatus.placing,
        product: product(),
        readiness: ready,
      );
      expect(state.isPurchasable, isFalse);
    });

    test('a missing product is not purchasable', () {
      const state = QuickCheckoutState(status: QuickCheckoutStatus.unavailable);
      expect(state.isPurchasable, isFalse);
    });
  });

  group('Low stock signalling', () {
    test('warns at or below five', () {
      for (final stock in [1, 3, 5]) {
        expect(
          QuickCheckoutState(product: product(stock: stock)).isLowStock,
          isTrue,
          reason: 'stock $stock should warn',
        );
      }
    });

    test('stays quiet above the threshold', () {
      // Showing an exact count on everything turns a genuine scarcity signal
      // into background noise nobody reads.
      expect(QuickCheckoutState(product: product(stock: 6)).isLowStock, isFalse);
      expect(
        QuickCheckoutState(product: product(stock: 99)).isLowStock,
        isFalse,
      );
    });

    test('sold out is not "low stock"', () {
      // Zero gets its own treatment — a disabled button, not a warning badge.
      expect(QuickCheckoutState(product: product(stock: 0)).isLowStock, isFalse);
    });

    test('no product means no warning rather than a crash', () {
      expect(const QuickCheckoutState().isLowStock, isFalse);
    });
  });

  group('The gate decides the button', () {
    test('a guest is asked to sign in first', () {
      // All four flags stated explicitly even where one matches its default:
      // this test is ABOUT the flag combination, so spelling it out is the
      // documentation. (The analyzer's avoid_redundant_argument_values fires
      // here; it is wrong about what makes this readable.)
      const state = QuickCheckoutState(
        
      );
      expect(state.gate, CheckoutGate.needsAccount);
    });

    test('identity is asked for before logistics', () {
      // Someone with an address but no verified phone must be sent to
      // verification, not to the address step. Bouncing them the other way is
      // the sequencing that loses a sale.
      const state = QuickCheckoutState(
        readiness: CheckoutReadiness(
          isGuest: false,
          hasVerifiedPhone: false,
          hasSavedAddress: true,
          hasPaymentMethod: true,
        ),
      );
      expect(state.gate, CheckoutGate.needsPhoneVerification);
    });
  });

  group('Buyer count', () {
    test('a brand-new product reports zero, not a fabricated figure', () {
      expect(const QuickCheckoutState().buyerCount, 0);
    });

    // REMOVED: 'reads from the product, not a constant'.
    //
    // It read:
    //
    //   final state = QuickCheckoutState(
    //     product: product(soldCount: 7),
    //     buyerCount: product(soldCount: 7).soldCount,
    //   );
    //   expect(state.buyerCount, 7);
    //
    // which passes `buyerCount: 7` in and asserts `buyerCount == 7` back out.
    // That holds for any value and for any implementation — it tests that a
    // constructor stores its argument, not that anything reads the product.
    //
    // The bug it names (214 buyers on every product, for several passes) lives
    // in QuickCheckoutCubit, which is what populates the field. Nothing in this
    // file could ever have caught it, because every state here is hand-built.
    //
    // The test that would catch it belongs at the cubit level: stub the product
    // repository to return a product with soldCount 7, load it, and assert the
    // EMITTED state carries 7. Worth writing — this is the one placeholder from
    // that era with no coverage at all now.
  });
}