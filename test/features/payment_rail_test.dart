import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/checkout/domain/entities/payment_method.dart';

void main() {
  group('Payment rails (§5.2)', () {
    test('cash on delivery needs no gateway', () {
      // COD skips the provider entirely — no webhook, no payment intent, the
      // order goes straight to confirmed.
      expect(PaymentRail.cashOnDelivery.requiresGateway, isFalse);
    });

    test('every electronic rail needs a gateway', () {
      for (final rail in PaymentRail.values) {
        if (rail == PaymentRail.cashOnDelivery) continue;
        expect(rail.requiresGateway, isTrue, reason: rail.name);
      }
    });

    test('cash is listed first — it leads Iraqi online orders by trust', () {
      expect(PaymentRail.values.first, PaymentRail.cashOnDelivery);
    });

    test('the cash constant carries a stable id the checkout can submit', () {
      expect(PaymentMethod.cash.id, 'cash_on_delivery');
      expect(PaymentMethod.cash.rail, PaymentRail.cashOnDelivery);
    });

    test('branded rails keep their brand name untranslated', () {
      // "ZainCash" is ZainCash in every language. Translating a provider name
      // would make the option unrecognisable beside the provider's own
      // branding.
      expect(PaymentRail.zainCash.brandName, 'ZainCash');
      expect(PaymentRail.asiaHawala.brandName, 'AsiaHawala');
      expect(PaymentRail.qiCard.brandName, 'Qi Card');
      expect(PaymentRail.zainCash.isBranded, isTrue);
    });

    test('generic rails carry no brand name and resolve through l10n', () {
      expect(PaymentRail.cashOnDelivery.isBranded, isFalse);
      expect(PaymentRail.bankCard.isBranded, isFalse);
    });

    test('a saved card exposes only a masked number', () {
      const card = PaymentMethod(
        id: 'pm_1',
        rail: PaymentRail.bankCard,
        lastFour: '4242',
      );
      expect(card.maskedNumber, '•••• 4242');
      expect(PaymentMethod.cash.maskedNumber, isNull);
    });
  });

  group('Phase 1 is cash-only', () {
    test('only cash on delivery is enabled', () {
      expect(PaymentRail.phase1EnabledRails, {PaymentRail.cashOnDelivery});
    });

    test('every other rail reports itself disabled', () {
      // Written as "all rails except cash" rather than listing them, so a rail
      // added later is covered without anyone remembering to update this.
      for (final rail in PaymentRail.values) {
        expect(
          rail.isEnabledThisPhase,
          rail == PaymentRail.cashOnDelivery,
          reason: '${rail.name} disagrees with phase1EnabledRails',
        );
      }
    });

    test('the paused rails still exist and keep their adapters intact', () {
      // Paused, not deleted. If someone "cleans up" by removing these enum
      // values, the ZainCash adapter and its tests stop compiling and Phase 2
      // becomes a rebuild rather than a one-line change.
      expect(PaymentRail.values, contains(PaymentRail.zainCash));
      expect(PaymentRail.zainCash.brandName, 'ZainCash');
      expect(PaymentRail.zainCash.requiresGateway, isTrue);
    });

    test('cash still needs no gateway, which is why it can ship alone', () {
      // The whole reason cash-only is viable as a phase: no provider call, no
      // webhook, no merchant account on the critical path.
      expect(PaymentRail.cashOnDelivery.requiresGateway, isFalse);
    });
  });
}
