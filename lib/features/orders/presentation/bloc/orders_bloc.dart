import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/orders/domain/repositories/order_repository.dart';

sealed class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

class OrdersSubscribed extends OrdersEvent {
  const OrdersSubscribed();
}

class _OrdersReceived extends OrdersEvent {
  const _OrdersReceived(this.orders);
  final List<Order> orders;
  @override
  List<Object?> get props => [orders];
}

enum OrdersStatus { loading, ready, failure }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.loading,
    this.orders = const [],
    this.failure,
  });

  final OrdersStatus status;
  final List<Order> orders;
  final Failure? failure;

  /// Delivered orders awaiting a rating. Surfaced separately so the UI can
  /// prompt without scanning the list itself.
  List<Order> get awaitingRating =>
      [for (final o in orders) if (o.canBeRated) o];

  OrdersState copyWith({
    OrdersStatus? status,
    List<Order>? orders,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      OrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [status, orders, failure];
}

/// Cancellation deliberately does NOT live here.
///
/// It is owned by the order detail screen, which also owns the confirmation
/// dialog. Two places to cancel an order is two places to get the
/// "window closes at handedToCourier" rule wrong, and a destructive action
/// with two implementations will eventually have two behaviours.
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc(this._repo) : super(const OrdersState()) {
    on<OrdersSubscribed>(_onSubscribed);
    on<_OrdersReceived>(
      (e, emit) => emit(
        state.copyWith(status: OrdersStatus.ready, orders: e.orders),
      ),
    );
  }

  final OrderRepository _repo;
  StreamSubscription<List<Order>>? _sub;

  Future<void> _onSubscribed(
    OrdersSubscribed e,
    Emitter<OrdersState> emit,
  ) async {
    await _sub?.cancel();
    _sub = _repo.watchMyOrders().listen(
          (orders) => add(_OrdersReceived(orders)),
          onError: (Object error) => emit(
            state.copyWith(
              status: OrdersStatus.failure,
              failure: const ServerFailure(
                'Could not load your orders',
                reason: FailureReason.ordersLoadFailed,
              ),
            ),
          ),
        );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
