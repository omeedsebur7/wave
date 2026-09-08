import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/idempotency.dart';
import 'package:wave/features/checkout/domain/entities/checkout_gate.dart';
import 'package:wave/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

enum QuickCheckoutStatus { loading, ready, placing, placed, unavailable, failed }

class QuickCheckoutState extends Equatable {
  const QuickCheckoutState({
    this.status = QuickCheckoutStatus.loading,
    this.product,
    this.sellerTier = TrustTier.newSeller,
    this.sellerKycVerified = false,
    this.buyerCount = 0,
    this.readiness = const CheckoutReadiness(
      isGuest: true,
      hasVerifiedPhone: false,
      hasSavedAddress: false,
      hasPaymentMethod: false,
    ),
    this.orderId,
    this.failure,
  });

  final QuickCheckoutStatus status;
  final Product? product;
  final TrustTier sellerTier;
  final bool sellerKycVerified;
  final int buyerCount;
  final CheckoutReadiness readiness;
  final String? orderId;
  final Failure? failure;

  CheckoutGate get gate => readiness.gate;

  bool get isLowStock {
    final stock = product?.stock ?? 0;
    return stock > 0 && stock <= 5;
  }

  bool get isPurchasable =>
      product != null && product!.inStock && status != QuickCheckoutStatus.placing;

  QuickCheckoutState copyWith({
    QuickCheckoutStatus? status,
    Product? product,
    TrustTier? sellerTier,
    bool? sellerKycVerified,
    int? buyerCount,
    CheckoutReadiness? readiness,
    String? orderId,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      QuickCheckoutState(
        status: status ?? this.status,
        product: product ?? this.product,
        sellerTier: sellerTier ?? this.sellerTier,
        sellerKycVerified: sellerKycVerified ?? this.sellerKycVerified,
        buyerCount: buyerCount ?? this.buyerCount,
        readiness: readiness ?? this.readiness,
        orderId: orderId ?? this.orderId,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props =>
      [status, product?.id, product?.stock, sellerTier, buyerCount, readiness,
       orderId, failure,];
}

class QuickCheckoutCubit extends Cubit<QuickCheckoutState> {
  QuickCheckoutCubit(this._products, this._checkout)
      : super(const QuickCheckoutState());

  final ProductRepository _products;
  final CheckoutRepository _checkout;
  final IdempotencyKey _idempotencyKey = IdempotencyKey.generate();

  String? _addressId;
  String? _paymentMethodId;

  Future<void> load(String productId) async {
    emit(state.copyWith(status: QuickCheckoutStatus.loading, clearFailure: true));

    final productResult = _products.byId(productId);
    final readinessResult = _checkout.readiness();
    final defaultsResult = _checkout.defaultSelections();

    final p = (await productResult).valueOrNull;
    final r = (await readinessResult).valueOrNull;
    final d = (await defaultsResult).valueOrNull;

    // FIXED: Guard against state modification after Cubit closes (§8.5)
    if (isClosed) return;

    if (p == null) {
      emit(state.copyWith(status: QuickCheckoutStatus.unavailable));
      return;
    }

    _addressId = d?.addressId;
    _paymentMethodId = d?.paymentMethodId;

    emit(
      state.copyWith(
        status: QuickCheckoutStatus.ready,
        product: p,
        sellerTier: p.sellerTier,
        sellerKycVerified: p.sellerKycVerified,
        buyerCount: p.soldCount,
        readiness: r ?? state.readiness,
      ),
    );
  }

  Future<void> placeOrder({
    required DeliveryLocation location,
    String? sourceReelId,
  }) async {
    final product = state.product;
    if (product == null || state.gate != CheckoutGate.ready) return;
    if (state.status == QuickCheckoutStatus.placing) return;

    emit(state.copyWith(status: QuickCheckoutStatus.placing, clearFailure: true));

    final addressId = _addressId;
    final paymentMethodId = _paymentMethodId;
    if (addressId == null || paymentMethodId == null) {
      emit(state.copyWith(
        status: QuickCheckoutStatus.failed,
        failure: const ServerFailure(
          'Finish setting up checkout first',
          reason: FailureReason.checkoutSetupIncomplete,
        ),
      ),);
      return;
    }

    if (!location.isValid) {
      emit(state.copyWith(
        status: QuickCheckoutStatus.failed,
        failure: const ServerFailure(
          'Set a delivery location first',
          reason: FailureReason.deliveryLocationRequired,
        ),
      ),);
      return;
    }

    final result = await _checkout.placeOrder(
      idempotencyKey: _idempotencyKey,
      items: [
        OrderItem(
          productId: product.id,
          title: product.title,
          unitPriceMinor: product.priceMinor,
          quantity: 1,
          imageUrl: product.primaryImage,
        ),
      ],
      addressId: addressId,
      paymentMethodId: paymentMethodId,
      sourceReelId: sourceReelId,
      deliveryLocation: location,
    );

    // FIXED: Guard against state modification after Cubit closes (§8.5)
    if (isClosed) return;

    result.fold(
      (f) => emit(
        state.copyWith(status: QuickCheckoutStatus.failed, failure: f),
      ),
      (order) => emit(
        state.copyWith(status: QuickCheckoutStatus.placed, orderId: order.id),
      ),
    );
  }
}
