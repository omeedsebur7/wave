import 'package:wave/core/utils/result.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

abstract class OrderRepository {
  /// Live stream rather than a one-shot fetch: an order's status changes while
  /// the user is looking at it, and "pull to refresh to see if it shipped" is
  /// exactly the friction the 3-step tracker exists to remove.
  Stream<List<Order>> watchMyOrders({int limit});

  Stream<Order?> watchOrder(String orderId);

  Future<Result<Order>> byId(String orderId);

  /// Only valid while the order is in the Confirmed stage (§5.2). The rule is
  /// enforced in Firestore Security Rules too — this check is for UX.
  Future<Result<void>> cancel(String orderId);
}
