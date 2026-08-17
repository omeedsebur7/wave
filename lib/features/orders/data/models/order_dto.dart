import 'package:cloud_firestore/cloud_firestore.dart'hide Order;
import 'package:wave/features/location/domain/entities/delivery_location.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

class OrderDto {
  const OrderDto({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.items,
    required this.totalMinor,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.idempotencyKey,
    this.sourceReelId,
    this.deliveredAt,
    this.hasBeenRated = false,
    this.deliveryLocation,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) => OrderDto(
        id: json['id'] as String,
        buyerId: json['buyer_id'] as String? ?? '',
        sellerId: json['seller_id'] as String? ?? '',
        items: [
          for (final i in (json['items'] as List? ?? []))
            OrderItem(
              productId: i['product_id'] as String,
              title: i['title'] as String? ?? '',
              unitPriceMinor: (i['unit_price_minor'] as num?)?.toInt() ?? 0,
              quantity: (i['quantity'] as num?)?.toInt() ?? 1,
              imageUrl: i['image_url'] as String? ?? '',
            ),
        ],
        totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'IQD',
        status: json['status'] as String? ?? 'confirmed',
        createdAt: _date(json['created_at']),
        // Null for orders placed before the map existed, and for full-checkout
        // orders that used a saved postal address. `fromJson` also returns null
        // for a stored pair that is out of range, so a corrupted document
        // renders as "no location" rather than pointing at the Atlantic.
        deliveryLocation: DeliveryLocation.fromJson(
          json['delivery_location'] as Map<String, dynamic>?,
        ),
        idempotencyKey: json['idempotency_key'] as String? ?? '',
        sourceReelId: json['source_reel_id'] as String?,
        deliveredAt: json['delivered_at'] == null
            ? null
            : _date(json['delivered_at']),
        hasBeenRated: json['has_been_rated'] as bool? ?? false,
      );

  static DateTime _date(Object? v) => switch (v) {
        final Timestamp t => t.toDate(),
        final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
        final String s => DateTime.tryParse(s) ?? DateTime.now(),
        _ => DateTime.now(),
      };

  final String id;
  final String buyerId;
  final String sellerId;
  final List<OrderItem> items;
  final int totalMinor;
  final String currency;
  final String status;
  final DateTime createdAt;
  final String idempotencyKey;
  final String? sourceReelId;
  final DateTime? deliveredAt;
  final bool hasBeenRated;
  final DeliveryLocation? deliveryLocation;

  Order toDomain() => Order(
        id: id,
        buyerId: buyerId,
        sellerId: sellerId,
        items: items,
        totalMinor: totalMinor,
        currency: currency,
        internalStatus: OrderInternalStatus.values.firstWhere(
          (s) => s.name == status,
          // An unknown status from a newer backend must not crash an older
          // client — degrade to "confirmed" and let the force-update gate
          // handle genuinely incompatible builds.
          orElse: () => OrderInternalStatus.confirmed,
        ),
        createdAt: createdAt,
        idempotencyKey: idempotencyKey,
        sourceReelId: sourceReelId,
        deliveredAt: deliveredAt,
        hasBeenRated: hasBeenRated,
        deliveryLocation: deliveryLocation,
      );
}
