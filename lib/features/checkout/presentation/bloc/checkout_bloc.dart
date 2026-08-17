import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart'hide Order;
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/idempotency.dart';
import 'package:wave/features/cart/domain/entities/cart.dart';
import 'package:wave/features/checkout/domain/entities/checkout_gate.dart';
import 'package:wave/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:wave/features/orders/domain/entities/order.dart';

sealed class CheckoutEvent extends Equatable {
  const CheckoutEvent();
  @override
  List<Object?> get props => [];
}

class CheckoutOpened extends CheckoutEvent {
  const CheckoutOpened(this.cart, {this.sourceReelId});
  final Cart cart;
  final String? sourceReelId;
  @override
  List<Object?> get props => [cart, sourceReelId];
}

/// Re-checks the gate after the user comes back from phone verification or
/// adding an address.
class CheckoutGateRechecked extends CheckoutEvent {
  const CheckoutGateRechecked();
}

class CheckoutAddressSelected extends CheckoutEvent {
  const CheckoutAddressSelected(this.addressId);
  final String addressId;
  @override
  List<Object?> get props => [addressId];
}

class CheckoutPaymentSelected extends CheckoutEvent {
  const CheckoutPaymentSelected(this.paymentMethodId);
  final String paymentMethodId;
  @override
  List<Object?> get props => [paymentMethodId];
}

class CheckoutSubmitted extends CheckoutEvent {
  const CheckoutSubmitted();
}

enum CheckoutStatus { loading, ready, submitting, success, failure }

class CheckoutState extends Equatable {
  const CheckoutState({
    required this.idempotencyKey,
    this.status = CheckoutStatus.loading,
    this.cart = const Cart(),
    this.readiness,
    this.addressId,
    this.paymentMethodId,
    this.placedOrder,
    this.failure,
    this.sourceReelId,
  });

  /// Generated ONCE, when checkout opens. Held in state for the whole session
  /// so every retry of every failed submit carries the same key.
  final IdempotencyKey idempotencyKey;

  final CheckoutStatus status;
  final Cart cart;
  final CheckoutReadiness? readiness;
  final String? addressId;
  final String? paymentMethodId;
  final Order? placedOrder;
  final Failure? failure;
  final String? sourceReelId;

  CheckoutGate get gate => readiness?.gate ?? CheckoutGate.needsAccount;

  bool get canSubmit =>
      gate.canProceedToPayment &&
      addressId != null &&
      paymentMethodId != null &&
      cart.canCheckout &&
      status != CheckoutStatus.submitting;

  CheckoutState copyWith({
    CheckoutStatus? status,
    Cart? cart,
    CheckoutReadiness? readiness,
    String? addressId,
    String? paymentMethodId,
    Order? placedOrder,
    Failure? failure,
    String? sourceReelId,
    bool clearFailure = false,
  }) =>
      CheckoutState(
        idempotencyKey: idempotencyKey, // never regenerated
        status: status ?? this.status,
        cart: cart ?? this.cart,
        readiness: readiness ?? this.readiness,
        addressId: addressId ?? this.addressId,
        paymentMethodId: paymentMethodId ?? this.paymentMethodId,
        placedOrder: placedOrder ?? this.placedOrder,
        failure: clearFailure ? null : (failure ?? this.failure),
        sourceReelId: sourceReelId ?? this.sourceReelId,
      );

  @override
  List<Object?> get props => [
        idempotencyKey.value,
        status,
        cart,
        readiness,
        addressId,
        paymentMethodId,
        placedOrder,
        failure,
      ];
}

@injectable
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  CheckoutBloc(this._repo, this._analytics)
      // The key is minted here, at construction — i.e. when the user opens
      // checkout, not when they tap Pay. This is the entire idempotency
      // contract. A key generated at tap time is a fresh key on every retry,
      // which is no protection at all, and retries are most frequent exactly
      // when the connection is worst.
      : super(CheckoutState(idempotencyKey: IdempotencyKey.generate())) {
    on<CheckoutOpened>(_onOpened);
    on<CheckoutGateRechecked>(_onGateRechecked);
    on<CheckoutAddressSelected>(
      (e, emit) => emit(state.copyWith(addressId: e.addressId)),
    );
    on<CheckoutPaymentSelected>(
      (e, emit) => emit(state.copyWith(paymentMethodId: e.paymentMethodId)),
    );
    on<CheckoutSubmitted>(_onSubmitted);
  }

  final CheckoutRepository _repo;
  final AnalyticsService _analytics;

  Future<void> _onOpened(
    CheckoutOpened e,
    Emitter<CheckoutState> emit,
  ) async {
    emit(
      state.copyWith(
        cart: e.cart,
        sourceReelId: e.sourceReelId,
        status: CheckoutStatus.loading,
      ),
    );
    await _loadReadiness(emit);
  }

  Future<void> _onGateRechecked(
    CheckoutGateRechecked e,
    Emitter<CheckoutState> emit,
  ) =>
      _loadReadiness(emit);

  Future<void> _loadReadiness(Emitter<CheckoutState> emit) async {
    final result = await _repo.readiness();
    result.fold(
      (f) => emit(state.copyWith(status: CheckoutStatus.failure, failure: f)),
      (r) {
        if (r.gate == CheckoutGate.needsPhoneVerification) {
          _analytics.log(AnalyticsEvents.checkoutGateShown);
        }
        emit(state.copyWith(status: CheckoutStatus.ready, readiness: r));
      },
    );
  }

  Future<void> _onSubmitted(
    CheckoutSubmitted e,
    Emitter<CheckoutState> emit,
  ) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(status: CheckoutStatus.submitting, clearFailure: true));

    final result = await _repo.placeOrder(
      idempotencyKey: state.idempotencyKey,
      items: [
        for (final l in state.cart.lines)
          OrderItem(
            productId: l.product.id,
            title: l.product.title,
            unitPriceMinor: l.product.priceMinor,
            quantity: l.quantity,
            imageUrl: l.product.primaryImage,
          ),
      ],
      addressId: state.addressId!,
      paymentMethodId: state.paymentMethodId!,
      sourceReelId: state.sourceReelId,
      promoCode: state.cart.promoCode,
    );

    result.fold(
      (f) => emit(state.copyWith(status: CheckoutStatus.failure, failure: f)),
      (order) {
        _analytics.log(
          AnalyticsEvents.purchaseCompleted,
          params: {
            AnalyticsParams.orderId: order.id,
            AnalyticsParams.value: order.totalMinor,
            AnalyticsParams.currency: order.currency,
            // Closes the Reel view -> Buy Now tap -> purchase chain (§5.1).
            if (order.sourceReelId != null)
              AnalyticsParams.reelId: order.sourceReelId!,
          },
        );
        emit(
          state.copyWith(status: CheckoutStatus.success, placedOrder: order),
        );
      },
    );
  }
}
