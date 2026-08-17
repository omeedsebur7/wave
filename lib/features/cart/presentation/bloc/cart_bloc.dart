import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:wave/features/cart/data/cart_store.dart';
import 'package:wave/features/cart/data/promo_repository.dart';
import 'package:wave/features/cart/domain/entities/cart.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();
  @override
  List<Object?> get props => [];
}

class CartItemAdded extends CartEvent {
  const CartItemAdded(this.product, {this.quantity = 1});
  final Product product;
  final int quantity;
  @override
  List<Object?> get props => [product.id, quantity];
}

class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);
  final String productId;
  @override
  List<Object?> get props => [productId];
}

class CartQuantityChanged extends CartEvent {
  const CartQuantityChanged(this.productId, this.quantity);
  final String productId;
  final int quantity;
  @override
  List<Object?> get props => [productId, quantity];
}

class CartPromoApplied extends CartEvent {
  const CartPromoApplied(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

class CartPromoRemoved extends CartEvent {
  const CartPromoRemoved();
}

class CartCleared extends CartEvent {
  const CartCleared();
}

/// Rehydrate from disk. Dispatched once at startup.
class CartRestored extends CartEvent {
  const CartRestored();
}

/// What the cart wants to tell the user, as a key rather than a sentence.
///
/// A BLoC has no BuildContext and therefore cannot resolve a translation.
/// Reaching for a global locale instead would produce a message in the wrong
/// language the moment someone switches language mid-session — and it would
/// make the BLoC untestable without a Flutter binding. The UI resolves this.
enum CartMessage {
  addedToCart,
  stockLimitReached,
  promoApplied,
  promoInvalid,
  promoExpired,
  promoUsed,
  promoBelowMinimum,
}

class CartState extends Equatable {
  const CartState({this.cart = const Cart(), this.message});

  final Cart cart;

  /// One-shot, for a SnackBar. Cleared by the next state.
  final CartMessage? message;

  CartState copyWith({Cart? cart, CartMessage? message}) =>
      CartState(cart: cart ?? this.cart, message: message);

  @override
  List<Object?> get props => [cart, message];
}

/// Cart is a singleton: the badge on the nav bar, the Buy Now sheet and the
/// cart page all have to agree, and a per-page instance would let them drift.
@lazySingleton
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._store, this._products, this._promos)
      : super(const CartState()) {
    on<CartItemAdded>(_onAdded);
    on<CartItemRemoved>(_onRemoved);
    on<CartQuantityChanged>(_onQuantityChanged);
    on<CartPromoApplied>(_onPromoApplied);
    on<CartPromoRemoved>(
      (_, emit) => emit(
        CartState(cart: state.cart.copyWith(clearPromo: true)),
      ),
    );
    on<CartCleared>(_onCleared);
    on<CartRestored>(_onRestored);

  }

  /// Persisted after every state change rather than on a timer or at dispose:
  /// the app is killed without warning, so there is no reliable later moment.
  ///
  /// Uses `onChange` rather than subscribing to the bloc's own `stream`. A
  /// self-subscription is not cancelled by `close()`, so it outlives the bloc —
  /// which in tests means writes firing after the bloc is closed, and in a hot
  /// reload means two subscriptions both persisting.
  @override
  void onChange(Change<CartState> change) {
    super.onChange(change);
    _persist(change.nextState);
  }

  final CartStore _store;
  final ProductRepository _products;
  final PromoRepository _promos;

  void _persist(CartState next) {
    // Takes the next state explicitly. Reading `state` inside `onChange` returns
    // the state being replaced, so persisting from it would always save the
    // cart as it was one change ago — and the last change before the app is
    // killed is the one that matters most.
    _store.save([
      for (final line in next.cart.lines)
        (productId: line.product.id, quantity: line.quantity),
    ]);
  }

  Future<void> _onCleared(CartCleared e, Emitter<CartState> emit) async {
    emit(const CartState());
    await _store.clear();
  }

  /// Rehydrates from disk, re-reading every product.
  ///
  /// Prices are deliberately NOT stored, so a restored cart shows what things
  /// cost now rather than what they cost last week — and anything sold out or
  /// withdrawn quietly drops out instead of sitting there un-buyable.
  Future<void> _onRestored(CartRestored e, Emitter<CartState> emit) async {
    final saved = _store.load();
    if (saved.isEmpty) return;

    final lines = <CartLine>[];
    for (final entry in saved) {
      final result = await _products.byId(entry.productId);
      final product = result.valueOrNull;
      if (product == null || !product.inStock) continue;

      lines.add(
        CartLine(
          product: product,
          // Clamped to current stock: a cart holding 5 of something with 2 left
          // would otherwise fail at checkout with no explanation.
          quantity: entry.quantity.clamp(1, product.stock),
        ),
      );
    }

    emit(CartState(cart: Cart(lines: lines)));
  }

  void _onAdded(CartItemAdded e, Emitter<CartState> emit) {
    final lines = [...state.cart.lines];
    final index = lines.indexWhere((l) => l.product.id == e.product.id);

    if (index == -1) {
      final qty = e.quantity.clamp(1, e.product.stock);
      lines.add(CartLine(product: e.product, quantity: qty));
    } else {
      // Adding the same product again bumps quantity rather than creating a
      // second line — two lines for one product is a checkout bug waiting to
      // happen.
      final newQty =
          (lines[index].quantity + e.quantity).clamp(1, e.product.stock);
      lines[index] = lines[index].copyWith(quantity: newQty);
    }

    final atLimit = lines
            .firstWhere((l) => l.product.id == e.product.id)
            .quantity ==
        e.product.stock;

    emit(
      CartState(
        cart: state.cart.copyWith(lines: lines),
        message: atLimit
            ? CartMessage.stockLimitReached
            : CartMessage.addedToCart,
      ),
    );
  }

  void _onRemoved(CartItemRemoved e, Emitter<CartState> emit) {
    emit(
      CartState(
        cart: state.cart.copyWith(
          lines: [
            for (final l in state.cart.lines)
              if (l.product.id != e.productId) l,
          ],
        ),
      ),
    );
  }

  void _onQuantityChanged(CartQuantityChanged e, Emitter<CartState> emit) {
    if (e.quantity < 1) {
      add(CartItemRemoved(e.productId));
      return;
    }
    emit(
      CartState(
        cart: state.cart.copyWith(
          lines: [
            for (final l in state.cart.lines)
              if (l.product.id == e.productId)
                l.copyWith(quantity: e.quantity.clamp(1, l.product.stock))
              else
                l,
          ],
        ),
      ),
    );
  }

  Future<void> _onPromoApplied(
    CartPromoApplied e,
    Emitter<CartState> emit,
  ) async {
    final code = e.code.trim().toUpperCase();
    if (code.isEmpty) return;

    // Checked before the order rather than during it.
    //
    // Without this, a mistyped code is only discovered when Place Order fails —
    // which is the right failure (a rejected code must never silently charge
    // full price) but a poor place to learn about a typo.
    //
    // The discount that comes back is a PREVIEW. `placeOrder` recomputes it
    // against the real cart, because a client-supplied discount is a
    // client-supplied price.
    final result = await _promos.validate(
      code: code,
      subtotalMinor: state.cart.subtotalMinor,
      sellerId: state.cart.lines.firstOrNull?.product.sellerId ?? '',
    );

    result.fold(
      (f) => emit(state.copyWith(message: CartMessage.promoInvalid)),
      (outcome) => emit(
        outcome.valid
            ? CartState(
                cart: state.cart.copyWith(
                  promoCode: code,
                  discountMinor: outcome.discountMinor,
                ),
                message: CartMessage.promoApplied,
              )
            : state.copyWith(message: outcome.message),
      ),
    );
  }
}
