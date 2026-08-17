import 'package:equatable/equatable.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';

/// Internal order lifecycle. Finer-grained than what the customer sees, on
/// purpose — ops and analytics need these states, customers don't (§5.2).
enum OrderInternalStatus {
  pendingPayment,
  paymentProcessing,
  paymentFailed,
  confirmed,
  packed,
  handedToCourier,
  outForDelivery,
  delivered,
  cancelled,
  refunded;

  /// The 3-step customer-facing tracker. Collapsing ~10 internal states into 3
  /// measurably cuts "where's my order" messages compared to exposing the full
  /// list — a longer status list reads as more information but generates more
  /// questions, not fewer.
  CustomerOrderStage get customerStage => switch (this) {
        OrderInternalStatus.pendingPayment ||
        OrderInternalStatus.paymentProcessing ||
        OrderInternalStatus.paymentFailed ||
        OrderInternalStatus.confirmed ||
        OrderInternalStatus.packed =>
          CustomerOrderStage.confirmed,
        OrderInternalStatus.handedToCourier ||
        OrderInternalStatus.outForDelivery =>
          CustomerOrderStage.onTheWay,
        OrderInternalStatus.delivered => CustomerOrderStage.delivered,
        OrderInternalStatus.cancelled ||
        OrderInternalStatus.refunded =>
          CustomerOrderStage.cancelled,
      };
}

enum CustomerOrderStage { confirmed, onTheWay, delivered, cancelled }

class Order extends Equatable {
  const Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.items,
    required this.totalMinor,
    required this.currency,
    required this.internalStatus,
    required this.createdAt,
    required this.idempotencyKey, this.deliveryLocation,
    this.sourceReelId,
    this.deliveredAt,
    this.hasBeenRated = false,
  });

  final String id;
  final String buyerId;
  final String sellerId;
  final List<OrderItem> items;

  /// Money is always minor units (fils/cents) in an int. Never a double —
  /// floating point and currency don't mix.
  final int totalMinor;
  final String currency;

  final OrderInternalStatus internalStatus;
  final DateTime createdAt;

  /// Where the buyer said to deliver, set on the map at Buy Now.
  ///
  /// Null for orders placed before the map existed, and for full-checkout
  /// orders that used a saved postal address instead — the seller UI has to
  /// handle both rather than assume a pin.
  final DeliveryLocation? deliveryLocation;

  /// Carried on the order itself so a redelivered webhook can be matched
  /// against an existing order rather than creating a second one (§5.2).
  final String idempotencyKey;

  /// Set when the order came from a Buy-Now tap, so the funnel can be joined
  /// back to the Reel that produced it (§5.1).
  final String? sourceReelId;

  final DateTime? deliveredAt;

  /// One rating per completed order (§5.2, anti-gaming).
  final bool hasBeenRated;

  CustomerOrderStage get stage => internalStatus.customerStage;

  /// Cancellation window closes when the order moves to "On the Way" (§5.2).
  bool get canCancel => stage == CustomerOrderStage.confirmed;

  /// The rating prompt only surfaces once an order reaches Delivered.
  bool get canBeRated =>
      internalStatus == OrderInternalStatus.delivered && !hasBeenRated;

  @override
  List<Object?> get props => [id, internalStatus, hasBeenRated];
}

class OrderItem extends Equatable {
  const OrderItem({
    required this.productId,
    required this.title,
    required this.unitPriceMinor,
    required this.quantity,
    required this.imageUrl,
  });

  final String productId;
  final String title;
  final int unitPriceMinor;
  final int quantity;
  final String imageUrl;

  int get lineTotalMinor => unitPriceMinor * quantity;

  @override
  List<Object?> get props => [productId, quantity, unitPriceMinor];
}
