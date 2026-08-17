import 'package:wave/core/utils/idempotency.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/checkout/domain/entities/checkout_gate.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

abstract class CheckoutRepository {
  Future<Result<CheckoutReadiness>> readiness();

  /// The address and payment method a one-tap purchase would use.
  ///
  /// Quick checkout has no picker by design — the whole claim is "one tap" — so
  /// it needs the defaults rather than the ability to choose. Returns nulls when
  /// nothing is saved, which the gate has already caught by then.
  Future<Result<({String? addressId, String? paymentMethodId})>>
      defaultSelections();

  /// Placing an order goes through a Cloud Function, never a direct client
  /// write. The client cannot be trusted with price, stock, or order totals —
  /// the function re-reads the product server-side and computes the total
  /// itself, so a tampered client can't buy a $500 item for $5.
  Future<Result<Order>> placeOrder({
    required IdempotencyKey idempotencyKey,
    required List<OrderItem> items,
    required String addressId,
    required String paymentMethodId,
    String? sourceReelId,
    String? promoCode,

    /// Where the courier is going. Required for a Buy Now order, which is why
    /// it is not optional at the call site even though the signature allows it
    /// — the full checkout supplies it from the saved address instead.
    DeliveryLocation? deliveryLocation,
  });
}
