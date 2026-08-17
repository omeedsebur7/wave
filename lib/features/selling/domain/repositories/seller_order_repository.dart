import 'package:wave/core/utils/result.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

/// The seller's side of the order lifecycle.
///
/// This is what closes the loop the whole trust system depends on. Without a
/// way for a seller to move an order forward, nothing ever reaches `delivered`;
/// without `delivered`, no rating can be left; without ratings, no seller ever
/// earns a tier badge. The chain runs through here.
abstract class SellerOrderRepository {
  Stream<List<Order>> watchIncoming({int limit});

  /// Advances an order one legal step. Illegal transitions are rejected here
  /// AND in Security Rules — an order that jumps from confirmed straight to
  /// delivered has skipped the point where the buyer's cancellation window
  /// should have closed.
  Future<Result<void>> advance(Order order, OrderInternalStatus to);

  Future<Result<void>> reject(Order order, {required String reason});
}

/// The legal state machine, in one place.
///
/// Kept as data rather than scattered `if` statements so the UI, the repository
/// and the tests all read the same rules — and so adding a state in Phase 2
/// (courier assignment, proof of delivery) is one edit, not a hunt.
abstract final class OrderTransitions {
  static const _allowed = <OrderInternalStatus, List<OrderInternalStatus>>{
    OrderInternalStatus.confirmed: [
      OrderInternalStatus.packed,
      OrderInternalStatus.cancelled,
    ],
    OrderInternalStatus.packed: [
      OrderInternalStatus.handedToCourier,
      OrderInternalStatus.cancelled,
    ],
    OrderInternalStatus.handedToCourier: [
      OrderInternalStatus.outForDelivery,
      OrderInternalStatus.delivered,
    ],
    OrderInternalStatus.outForDelivery: [
      OrderInternalStatus.delivered,
    ],
    // Terminal. An order does not come back from delivered, cancelled or
    // refunded — reopening one would let a seller retroactively erase a rating
    // by bouncing the order out of a rateable state.
    OrderInternalStatus.delivered: [],
    OrderInternalStatus.cancelled: [],
    OrderInternalStatus.refunded: [],
    OrderInternalStatus.pendingPayment: [OrderInternalStatus.cancelled],
    OrderInternalStatus.paymentProcessing: [OrderInternalStatus.cancelled],
    OrderInternalStatus.paymentFailed: [OrderInternalStatus.cancelled],
  };

  static List<OrderInternalStatus> nextFrom(OrderInternalStatus from) =>
      _allowed[from] ?? const [];

  static bool isLegal(OrderInternalStatus from, OrderInternalStatus to) =>
      nextFrom(from).contains(to);

  static bool isTerminal(OrderInternalStatus status) =>
      nextFrom(status).isEmpty;

  /// The single action a seller most likely wants next, for the primary button.
  /// Everything else goes behind a menu — a row of five equal buttons makes the
  /// common case as slow as the rare one.
  static OrderInternalStatus? primaryNext(OrderInternalStatus from) =>
      switch (from) {
        OrderInternalStatus.confirmed => OrderInternalStatus.packed,
        OrderInternalStatus.packed => OrderInternalStatus.handedToCourier,
        OrderInternalStatus.handedToCourier =>
          OrderInternalStatus.outForDelivery,
        OrderInternalStatus.outForDelivery => OrderInternalStatus.delivered,
        _ => null,
      };

  // `actionLabel` deliberately does not live here.
  //
  // These are the buttons a seller taps to move an order forward — the most
  // used controls in the whole seller experience — and this is a domain class
  // with no `BuildContext`, so labels defined here could never translate. The
  // seventh instance of this trap in the codebase. Resolved by
  // `orderActionLabel` in the presentation layer.
  //
  // The old fallback arm was `_ => to.name`, which would have rendered a raw
  // enum identifier like `handedToCourier` to a seller if a transition were
  // ever added without a label. The resolver is exhaustive instead, so that
  // omission becomes a compile error rather than leaked jargon.
}
