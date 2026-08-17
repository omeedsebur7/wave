import 'package:flutter/widgets.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

/// The label on the button that advances an order.
///
/// Lives in the presentation layer because `OrderTransitions` is a domain class
/// with no `BuildContext`. These are the most-tapped controls in the seller
/// experience, and a label defined next to the state machine could never
/// translate — the seventh place in this codebase where that trap had to be
/// undone.
///
/// Exhaustive on purpose, with no fallback arm. The previous version ended in
/// `_ => to.name`, which meant adding a transition without a label would render
/// a raw enum identifier — `handedToCourier` — to a seller in production. A
/// missing arm is now a compile error, which is where that mistake belongs.
///
/// The wording matters more than it looks. "Mark as packed" describes what the
/// seller is asserting, not what the app is doing, because these transitions are
/// claims about the physical world that only the seller can make — and the trust
/// tier is computed from them.
String orderActionLabel(BuildContext context, OrderInternalStatus to) =>
    switch (to) {
      OrderInternalStatus.packed => context.l10n.actionMarkPacked,
      OrderInternalStatus.handedToCourier => context.l10n.actionHandedToCourier,
      OrderInternalStatus.outForDelivery => context.l10n.actionOutForDelivery,
      OrderInternalStatus.delivered => context.l10n.actionMarkDelivered,
      OrderInternalStatus.cancelled => context.l10n.actionCancelOrder,

      // The remaining states are never offered as an action a seller can take:
      // the payment states resolve on their own (and are unreachable at all in
      // the cash-only phase), `confirmed` is where an order arrives rather than
      // somewhere it is moved to, and `refunded` is set by the refund path.
      //
      // Listed explicitly rather than collapsed into `_` so that adding a new
      // status forces a decision here instead of silently falling through.
      OrderInternalStatus.pendingPayment ||
      OrderInternalStatus.paymentProcessing ||
      OrderInternalStatus.paymentFailed ||
      OrderInternalStatus.confirmed ||
      OrderInternalStatus.refunded =>
        throw ArgumentError('$to is not a seller-initiated transition'),
    };
