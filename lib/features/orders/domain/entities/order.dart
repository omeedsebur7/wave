import 'package:equatable/equatable.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';

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
    required this.idempotencyKey, 
    this.deliveryLocation,
    this.sourceReelId,
    this.deliveredAt,
    this.hasBeenRated = false,
  });

  final String id;
  final String buyerId;
  final String sellerId;
  final List<OrderItem> items;
  final int totalMinor;
  final String currency;
  final OrderInternalStatus internalStatus;
  final DateTime createdAt;
  final DeliveryLocation? deliveryLocation;
  final String idempotencyKey;
  final String? sourceReelId;
  final DateTime? deliveredAt;
  final bool hasBeenRated;

  CustomerOrderStage get stage => internalStatus.customerStage;

  bool get canCancel => stage == CustomerOrderStage.confirmed;

  bool get canBeRated =>
      internalStatus == OrderInternalStatus.delivered && !hasBeenRated;

  // FIXED: Included all relevant fields for accurate state comparison.
  @override
  List<Object?> get props => [
        id, 
        buyerId,
        sellerId,
        items,
        totalMinor,
        currency,
        internalStatus, 
        createdAt,
        idempotencyKey,
        deliveryLocation,
        sourceReelId,
        deliveredAt,
        hasBeenRated,
      ];
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

  // FIXED: Included title and imageUrl for accurate state comparison.
  @override
  List<Object?> get props => [productId, title, unitPriceMinor, quantity, imageUrl];
}
