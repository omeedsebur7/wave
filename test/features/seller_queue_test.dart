import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/selling/presentation/bloc/seller_orders_bloc.dart';

/// What lands in a seller's "to do" queue.
///
/// This filtered on `CustomerOrderStage` for several passes, which folds five
/// internal states into one word for the buyer's benefit. The consequence was
/// that an order still settling appeared in the seller's queue telling them to
/// pack something nobody had paid for.
void main() {
  Order order(OrderInternalStatus status) => Order(
        id: 'o_${status.name}',
        buyerId: 'b1',
        sellerId: 's1',
        items: const [],
        totalMinor: 25000,
        currency: 'IQD',
        internalStatus: status,
        // Distinct per order, not a shared constant. The key exists to make one
        // placement attempt collapse into one order, so a fixture where several
        // orders share a key models a state the server would have refused to
        // create — and any future dedupe assertion built on this helper would
        // be testing against an impossible fixture.
        idempotencyKey: 'idem_${status.name}',
        // UTC, and the day omitted because it is the default. A local-time
        // fixture makes the value depend on the machine running the suite.
        createdAt: DateTime.utc(2026, 8),
      );

  SellerOrdersState withAll() => SellerOrdersState(
        orders: [for (final s in OrderInternalStatus.values) order(s)],
      );

  group('Needs-action queue', () {
    test('includes orders that are paid and waiting on the seller', () {
      final visible = withAll().visible.map((o) => o.internalStatus).toSet();
      expect(visible, {
        OrderInternalStatus.confirmed,
        OrderInternalStatus.packed,
      });
    });

    test('excludes orders still settling', () {
      // The bug this test exists for. An unpaid order in the queue means a
      // seller packs early, or learns to distrust the queue — both bad.
      final visible = withAll().visible.map((o) => o.internalStatus);
      expect(visible, isNot(contains(OrderInternalStatus.pendingPayment)));
      expect(visible, isNot(contains(OrderInternalStatus.paymentProcessing)));
      expect(visible, isNot(contains(OrderInternalStatus.paymentFailed)));
    });

    test('excludes orders already with a courier', () {
      final visible = withAll().visible.map((o) => o.internalStatus);
      expect(visible, isNot(contains(OrderInternalStatus.handedToCourier)));
      expect(visible, isNot(contains(OrderInternalStatus.outForDelivery)));
    });

    test('excludes anything finished', () {
      final visible = withAll().visible.map((o) => o.internalStatus);
      expect(visible, isNot(contains(OrderInternalStatus.delivered)));
      expect(visible, isNot(contains(OrderInternalStatus.cancelled)));
      expect(visible, isNot(contains(OrderInternalStatus.refunded)));
    });
  });

  group('The badge counts the same thing the queue shows', () {
    test('badge matches the needs-action list exactly', () {
      // A badge that disagrees with the list is worse than no badge: it sends
      // someone looking for work that is not there.
      final state = withAll();
      expect(state.needsActionCount, state.visible.length);
    });

    test('unpaid orders are counted separately, not ignored', () {
      // A seller seeing traffic and no orders deserves to know some are stuck
      // settling rather than concluding nobody is buying.
      //
      // The 2 is pendingPayment + paymentProcessing — paymentFailed is excluded
      // from the queue above but is NOT "awaiting" anything, so it is correctly
      // not counted here.
      //
      // Note the coupling: withAll() enumerates OrderInternalStatus.values, so
      // adding a payment state to that enum silently changes the right answer
      // and this test starts failing on a line that did not change. That is the
      // good failure mode — but the fix when it happens is to update the 2
      // deliberately, not to make the expectation self-referential the way
      // needsActionCount is above. A count that derives from the thing it
      // checks would stop testing anything.
      expect(withAll().awaitingPaymentCount, 2);
    });
  });

  group('The other two filters', () {
    test('in-transit covers exactly the courier states', () {
      final state = withAll().copyWith(filter: SellerOrderFilter.inTransit);
      expect(
        state.visible.map((o) => o.internalStatus).toSet(),
        {
          OrderInternalStatus.handedToCourier,
          OrderInternalStatus.outForDelivery,
        },
      );
    });

    test('completed covers delivered and both cancelled forms', () {
      final state = withAll().copyWith(filter: SellerOrderFilter.completed);
      expect(
        state.visible.map((o) => o.internalStatus).toSet(),
        {
          OrderInternalStatus.delivered,
          OrderInternalStatus.cancelled,
          OrderInternalStatus.refunded,
        },
      );
    });

    test('every internal status lands in at most one bucket', () {
      // Overlapping filters mean an order a seller "handled" reappears
      // elsewhere, which reads as the app losing track of it.
      final buckets = {
        for (final f in SellerOrderFilter.values)
          f: withAll().copyWith(filter: f).visible.map((o) => o.id).toSet(),
      };
      final all = buckets.values.expand((s) => s).toList();
      expect(
        all.length,
        all.toSet().length,
        reason: 'an order appears in more than one filter',
      );
    });
  });
}
