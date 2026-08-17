import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/checkout/domain/entities/checkout_gate.dart';

void main() {
  group('Checkout identity gate (§1, §5.2)', () {
    test('a guest is stopped at "needs account" first', () {
      const r = CheckoutReadiness(
        isGuest: true,
        hasVerifiedPhone: false,
        hasSavedAddress: false,
        hasPaymentMethod: false,
      );
      expect(r.gate, CheckoutGate.needsAccount);
    });

    test(
      'a Google/Apple user without a verified phone is stopped BEFORE address',
      () {
        // Sequencing matters commercially: making someone type an address and
        // then bouncing them to SMS verification is how you lose the sale.
        const r = CheckoutReadiness(
          isGuest: false,
          hasVerifiedPhone: false,
          hasSavedAddress: false,
          hasPaymentMethod: false,
        );
        expect(r.gate, CheckoutGate.needsPhoneVerification);
      },
    );

    test('verification is per USER, not per order — once on file it is done', () {
      const r = CheckoutReadiness(
        isGuest: false,
        hasVerifiedPhone: true,
        hasSavedAddress: true,
        hasPaymentMethod: true,
      );
      expect(r.gate, CheckoutGate.ready);
      expect(r.supportsOneTap, isTrue);
    });

    test('one-tap requires every precondition', () {
      const missingPayment = CheckoutReadiness(
        isGuest: false,
        hasVerifiedPhone: true,
        hasSavedAddress: true,
        hasPaymentMethod: false,
      );
      expect(missingPayment.supportsOneTap, isFalse);
      expect(missingPayment.gate.canProceedToPayment, isFalse);
    });
  });
}
