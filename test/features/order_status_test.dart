import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

void main() {
  group('Internal status collapses to the 3-step customer tracker (§5.2)', () {
    test('every pre-shipping state reads as Confirmed', () {
      for (final s in [
        OrderInternalStatus.pendingPayment,
        OrderInternalStatus.paymentProcessing,
        OrderInternalStatus.confirmed,
        OrderInternalStatus.packed,
      ]) {
        expect(s.customerStage, CustomerOrderStage.confirmed,
            reason: '$s should not expose internal detail to the buyer',);
      }
    });

    test('courier states read as On the way', () {
      expect(OrderInternalStatus.handedToCourier.customerStage,
          CustomerOrderStage.onTheWay,);
      expect(OrderInternalStatus.outForDelivery.customerStage,
          CustomerOrderStage.onTheWay,);
    });

    test('every internal status maps to a stage — no unhandled case', () {
      for (final s in OrderInternalStatus.values) {
        expect(() => s.customerStage, returnsNormally);
      }
    });
  });

  group('Cancellation window', () {
    Order orderWith(OrderInternalStatus status) => Order(
          id: 'o1',
          buyerId: 'b',
          sellerId: 's',
          items: const [],
          totalMinor: 1000,
          currency: 'IQD',
          internalStatus: status,
          createdAt: DateTime(2026),
          idempotencyKey: 'key',
        );

    test('open while the order is still Confirmed', () {
      expect(orderWith(OrderInternalStatus.confirmed).canCancel, isTrue);
      expect(orderWith(OrderInternalStatus.packed).canCancel, isTrue);
    });

    test('closes the moment it moves to On the way', () {
      expect(orderWith(OrderInternalStatus.handedToCourier).canCancel, isFalse);
      expect(orderWith(OrderInternalStatus.delivered).canCancel, isFalse);
    });
  });

  group('Rating prompt', () {
    test('only appears once delivered, and only once', () {
      final delivered = Order(
        id: 'o', buyerId: 'b', sellerId: 's', items: const [],
        totalMinor: 1, currency: 'IQD',
        internalStatus: OrderInternalStatus.delivered,
        createdAt: DateTime(2026), idempotencyKey: 'k',
      );
      expect(delivered.canBeRated, isTrue);

      final alreadyRated = Order(
        id: 'o', buyerId: 'b', sellerId: 's', items: const [],
        totalMinor: 1, currency: 'IQD',
        internalStatus: OrderInternalStatus.delivered,
        createdAt: DateTime(2026), idempotencyKey: 'k',
        hasBeenRated: true,
      );
      expect(alreadyRated.canBeRated, isFalse);
    });
  });
}
