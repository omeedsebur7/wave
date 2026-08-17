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

  /// How many people have bought this item. Zero is rendered as "be the first"
  /// rather than "0 people bought this", which reads as a warning.
  final int buyerCount;

  final CheckoutReadiness readiness;
  final String? orderId;
  final Failure? failure;

  CheckoutGate get gate => readiness.gate;

  /// Stock is low enough to be worth saying so.
  ///
  /// Threshold rather than exact count: "only 3 left" on something with 3 left
  /// is honest, but showing an exact figure on every product turns a genuine
  /// scarcity signal into background noise nobody reads.
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

/// Backs the Buy Now sheet (§5.1).
///
/// This is the shortest path between watching and owning, and the one the whole
/// product is built around, so it does as little as it can get away with: one
/// read of the product, one read of readiness, and — when nothing is missing —
/// one call to `placeOrder`.
class QuickCheckoutCubit extends Cubit<QuickCheckoutState> {
  QuickCheckoutCubit(this._products, this._checkout)
      : super(const QuickCheckoutState());

  final ProductRepository _products;
  final CheckoutRepository _checkout;

  /// Generated when the sheet OPENS, not when Buy Now is tapped.
  ///
  /// Same reasoning as the full checkout: a key created at tap time is a new key
  /// on every retry, so a double tap or a retry after a timeout becomes two
  /// orders and two charges. Created once here, it survives every attempt within
  /// this sheet.
  final IdempotencyKey _idempotencyKey = IdempotencyKey.generate();

  /// Resolved at load, so the tap itself does no extra reads. A one-tap purchase
  /// that fires two round-trips before it starts is not one tap.
  String? _addressId;
  String? _paymentMethodId;

  Future<void> load(String productId) async {
    emit(state.copyWith(status: QuickCheckoutStatus.loading, clearFailure: true));

    // Three reads in parallel. Serialised, this is the delay between tapping
    // Buy Now and seeing a price — the moment a buying decision is most fragile.
    final productResult = _products.byId(productId);
    final readinessResult = _checkout.readiness();
    final defaultsResult = _checkout.defaultSelections();

    final product = (await productResult).valueOrNull;
    if (product == null) {
      // The listing was withdrawn between the feed loading and the tap. A
      // scheduled function unlinks these from Reels, but it is not instant, and
      // the person tapping deserves an explanation rather than an empty sheet.
      emit(state.copyWith(status: QuickCheckoutStatus.unavailable));
      return;
    }

    final defaults = (await defaultsResult).valueOrNull;
    _addressId = defaults?.addressId;
    _paymentMethodId = defaults?.paymentMethodId;

    emit(
      state.copyWith(
        status: QuickCheckoutStatus.ready,
        product: product,
        sellerTier: product.sellerTier,
        sellerKycVerified: product.sellerKycVerified,
        buyerCount: product.soldCount,
        readiness: (await readinessResult).valueOrNull ?? state.readiness,
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
      // The gate should have caught this. Reaching here means readiness and the
      // saved details disagreed, so refuse rather than guess — a one-tap order
      // sent to an address nobody chose is worse than a refused tap.
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
      // Should be unreachable — the picker's confirm button is disabled for an
      // invalid pin — but an order carrying nonsense coordinates sends a
      // courier somewhere real and wrong, which is worse than a refused tap.
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
          // Sent for the receipt only. `placeOrder` re-reads every price from
          // the product document server-side and ignores what arrives here.
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
