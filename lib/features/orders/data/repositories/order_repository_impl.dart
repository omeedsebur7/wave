import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/error/transaction_aborted.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/orders/data/models/order_dto.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._db, this._auth, this._analytics);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final AnalyticsService _analytics;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  String? get _uid => _auth.currentUser?.uid;

  @override
  Stream<List<Order>> watchMyOrders({int limit = 50}) {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);

    return _orders
        .where('buyer_id', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              OrderDto.fromJson({'id': doc.id, ...doc.data()}).toDomain(),
          ],
        );
  }

  @override
  Stream<Order?> watchOrder(String orderId) {
    // §6 asks for tracker-view rate. It is the measure of whether the 3-step
    // simplification worked: if people still open the tracker repeatedly, the
    // status is not answering their question and they will message instead.
    _analytics.log(
      AnalyticsEvents.orderTrackerViewed,
      params: {AnalyticsParams.orderId: orderId},
    );

    return _orders.doc(orderId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return OrderDto.fromJson({'id': doc.id, ...data}).toDomain();
    });
  }

  @override
  Future<Result<Order>> byId(String orderId) async {
    try {
      final doc = await _orders.doc(orderId).get();
      final data = doc.data();
      if (data == null) {
        return const Err(
          NotFoundFailure('Order not found', FailureReason.orderNotFound),
        );
      }
      return Success(OrderDto.fromJson({'id': doc.id, ...data}).toDomain());
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  @override
  Future<Result<void>> cancel(String orderId) async {
    try {
      // Read-then-write inside a transaction, because the window closes on a
      // status change the seller can make at any moment. Checking outside a
      // transaction leaves a gap where the order ships between the check and
      // the write, and the customer sees "cancelled" for something already in
      // a van.
      await _db.runTransaction((tx) async {
        final ref = _orders.doc(orderId);
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) {
          throw const TransactionAborted(
            NotFoundFailure('Order not found', FailureReason.orderNotFound),
          );
        }

        final order = OrderDto.fromJson({'id': snap.id, ...data}).toDomain();

        if (order.buyerId != _uid) {
          throw const TransactionAborted(
            PermissionFailure('This is not your order', FailureReason.notYourOrder),
          );
        }
        if (!order.canCancel) {
          throw const TransactionAborted(
            ServerFailure(
              'This order has already left for delivery and can no longer '
              'be cancelled. Message the seller to sort it out.',
              reason: FailureReason.orderAlreadyShipped,
            ),
          );
        }

        tx.update(ref, {
          'status': OrderInternalStatus.cancelled.name,
          'cancelled_at': FieldValue.serverTimestamp(),
          // Attribution, not decoration. It feeds the fulfilment gate on the
          // seller's tier, and Security Rules pin it to 'buyer' on this path so
          // neither side can misattribute a cancellation to the other.
          'cancelled_by': 'buyer',
        });
      });

      await _analytics.log(
        AnalyticsEvents.orderCancelled,
        params: {AnalyticsParams.orderId: orderId, 'cancelled_by': 'buyer'},
      );

      return const Success(null);
    } on TransactionAborted catch (aborted) {
      return Err(aborted.failure);
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Could not cancel',
          code: e.code,
          reason: FailureReason.cancelFailed,
        ),
      );
    }
  }
}
