import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/selling/domain/repositories/seller_order_repository.dart';

sealed class SellerOrdersEvent extends Equatable {
  const SellerOrdersEvent();
  @override
  List<Object?> get props => [];
}

class SellerOrdersSubscribed extends SellerOrdersEvent {
  const SellerOrdersSubscribed();
}

class _SellerOrdersReceived extends SellerOrdersEvent {
  const _SellerOrdersReceived(this.orders);
  final List<Order> orders;
  @override
  List<Object?> get props => [orders];
}

class SellerOrderAdvanced extends SellerOrdersEvent {
  const SellerOrderAdvanced(this.order, this.to);
  final Order order;
  final OrderInternalStatus to;
  @override
  List<Object?> get props => [order.id, to];
}

class SellerOrderFilterChanged extends SellerOrdersEvent {
  const SellerOrderFilterChanged(this.filter);
  final SellerOrderFilter filter;
  @override
  List<Object?> get props => [filter];
}

/// Needs-action first, because that is the only view a seller opens the app for.
///
/// Labels are resolved at render rather than carried on the enum — an enum
/// constant cannot reach a BuildContext, and a hardcoded label here would be
/// the one string on the screen that never translates.
enum SellerOrderFilter { needsAction, inTransit, completed }

enum SellerOrdersStatus { loading, ready, failure }

class SellerOrdersState extends Equatable {
  const SellerOrdersState({
    this.status = SellerOrdersStatus.loading,
    this.orders = const [],
    this.filter = SellerOrderFilter.needsAction,
    this.updatingId,
    this.failure,
  });

  final SellerOrdersStatus status;
  final List<Order> orders;
  final SellerOrderFilter filter;
  final String? updatingId;
  final Failure? failure;

  List<Order> get visible => [
        for (final o in orders)
          if (_matches(o)) o,
      ];

  /// Filters on the INTERNAL status, not the customer stage.
  ///
  /// `CustomerOrderStage` is a deliberate simplification for buyers — it folds
  /// `pendingPayment`, `paymentProcessing`, `paymentFailed`, `confirmed` and
  /// `packed` into one word. A seller needs the distinction those states carry,
  /// and filtering on the buyer's view would put an unpaid order in the "to do"
  /// queue, telling a seller to pack something nobody has paid for.
  bool _matches(Order o) => switch (filter) {
        SellerOrderFilter.needsAction => _awaitingSeller(o),
        SellerOrderFilter.inTransit => o.stage == CustomerOrderStage.onTheWay,
        SellerOrderFilter.completed =>
          o.stage == CustomerOrderStage.delivered ||
              o.stage == CustomerOrderStage.cancelled,
      };

  /// Paid for, and waiting on the seller to do something.
  ///
  /// Excludes the payment states on purpose. An order still settling is not the
  /// seller's problem yet, and showing it would either have them pack early or
  /// train them to ignore the queue.
  static bool _awaitingSeller(Order o) =>
      o.internalStatus == OrderInternalStatus.confirmed ||
      o.internalStatus == OrderInternalStatus.packed;

  /// Drives the badge on the tab. A seller who does not know an order is
  /// waiting is a seller whose buyer is about to message asking why — and a
  /// badge that counts unpaid orders is one they learn to distrust.
  int get needsActionCount => [
        for (final o in orders)
          if (_awaitingSeller(o)) o,
      ].length;

  /// Orders held up in payment. Not actionable, but worth surfacing somewhere:
  /// a seller seeing traffic and no orders deserves to know some are stuck
  /// settling rather than concluding nobody is buying.
  int get awaitingPaymentCount => [
        for (final o in orders)
          if (o.internalStatus == OrderInternalStatus.pendingPayment ||
              o.internalStatus == OrderInternalStatus.paymentProcessing)
            o,
      ].length;

  SellerOrdersState copyWith({
    SellerOrdersStatus? status,
    List<Order>? orders,
    SellerOrderFilter? filter,
    String? updatingId,
    Failure? failure,
    bool clearUpdating = false,
    bool clearFailure = false,
  }) =>
      SellerOrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        filter: filter ?? this.filter,
        updatingId: clearUpdating ? null : (updatingId ?? this.updatingId),
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [status, orders, filter, updatingId, failure];
}

class SellerOrdersBloc extends Bloc<SellerOrdersEvent, SellerOrdersState> {
  SellerOrdersBloc(this._repo) : super(const SellerOrdersState()) {
    on<SellerOrdersSubscribed>(_onSubscribed);
    on<_SellerOrdersReceived>(
      (e, emit) => emit(
        state.copyWith(status: SellerOrdersStatus.ready, orders: e.orders),
      ),
    );
    on<SellerOrderAdvanced>(_onAdvanced);
    on<SellerOrderFilterChanged>(
      (e, emit) => emit(state.copyWith(filter: e.filter)),
    );
  }

  final SellerOrderRepository _repo;
  StreamSubscription<List<Order>>? _sub;

  Future<void> _onSubscribed(
    SellerOrdersSubscribed e,
    Emitter<SellerOrdersState> emit,
  ) async {
    await _sub?.cancel();
    _sub = _repo.watchIncoming().listen(
          (orders) => add(_SellerOrdersReceived(orders)),
          onError: (Object _) => emit(
            state.copyWith(
              status: SellerOrdersStatus.failure,
              failure: const ServerFailure(
              'Could not load your orders',
              reason: FailureReason.ordersLoadFailed,
            ),
            ),
          ),
        );
  }

  Future<void> _onAdvanced(
    SellerOrderAdvanced e,
    Emitter<SellerOrdersState> emit,
  ) async {
    emit(state.copyWith(updatingId: e.order.id, clearFailure: true));

    final result = await _repo.advance(e.order, e.to);
    result.fold(
      (f) => emit(state.copyWith(failure: f, clearUpdating: true)),
      // No manual list edit — the Firestore stream delivers the new status, so
      // there is one path for changes whether they came from this device or
      // from the buyer cancelling on theirs.
      (_) => emit(state.copyWith(clearUpdating: true)),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
