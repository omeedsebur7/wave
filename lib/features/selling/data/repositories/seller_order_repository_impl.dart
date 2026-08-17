import 'package:cloud_firestore/cloud_firestore.dart'hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/orders/data/models/order_dto.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/selling/domain/repositories/seller_order_repository.dart';

class SellerOrderRepositoryImpl implements SellerOrderRepository {
  SellerOrderRepositoryImpl(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  @override
  Stream<List<Order>> watchIncoming({int limit = 100}) {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);

    return _db
        .collection('orders')
        .where('seller_id', isEqualTo: uid)
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
  Future<Result<void>> advance(Order order, OrderInternalStatus to) async {
    final uid = _uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Not signed in', reason: FailureReason.notSignedIn),
      );
    }
    if (order.sellerId != uid) {
      return const Err(
        PermissionFailure(
          'This is not your order',
          FailureReason.notYourOrder,
        ),
      );
    }

    if (!OrderTransitions.isLegal(order.internalStatus, to)) {
      return Err(
        ServerFailure(
          'An order cannot go from '
          '${order.internalStatus.name} to ${to.name}.',
          reason: FailureReason.invalidStatusTransition,
        ),
      );
    }

    try {
      // Transactional, and it re-reads the status inside the transaction. The
      // buyer may be cancelling at the same moment the seller taps "packed";
      // whichever write lands first wins, and the loser is told why rather
      // than silently overwriting.
      await _db.runTransaction((tx) async {
        final ref = _db.collection('orders').doc(order.id);
        final snap = await tx.get(ref);
        final data = snap.data();
        if (data == null) {
          throw const NotFoundFailure(
            'Order not found',
            FailureReason.orderNotFound,
          );
        }

        final current = OrderInternalStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => OrderInternalStatus.confirmed,
        );

        if (current == OrderInternalStatus.cancelled) {
          throw const ServerFailure(
            'The buyer cancelled this order while you were updating it.',
            reason: FailureReason.buyerCancelledOrder,
          );
        }
        if (!OrderTransitions.isLegal(current, to)) {
          throw const ServerFailure(
            'This order already moved on. Pull to refresh.',
            reason: FailureReason.orderMovedOn,
          );
        }

        tx.update(ref, {
          'status': to.name,
          '${to.name}_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          if (to == OrderInternalStatus.delivered)
            'delivered_at': FieldValue.serverTimestamp(),
        });
      });

      return const Success(null);
    } on Failure catch (f) {
      return Err(f);
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Could not update',
          code: e.code,
          reason: FailureReason.orderUpdateFailed,
        ),
      );
    }
  }

  @override
  Future<Result<void>> reject(Order order, {required String reason}) async {
    final uid = _uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Not signed in', reason: FailureReason.notSignedIn),
      );
    }
    if (order.sellerId != uid) {
      return const Err(
        PermissionFailure(
          'This is not your order',
          FailureReason.notYourOrder,
        ),
      );
    }

    try {
      await _db.collection('orders').doc(order.id).update({
        'status': OrderInternalStatus.cancelled.name,
        'cancelled_by': 'seller',
        // Recorded, because a seller who routinely rejects orders after
        // accepting them is a pattern worth being able to see later.
        'cancellation_reason': reason,
        'cancelled_at': FieldValue.serverTimestamp(),
      });
      return const Success(null);
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
