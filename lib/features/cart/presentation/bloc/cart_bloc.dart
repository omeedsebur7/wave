import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

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

class CartRestored extends CartEvent {
  const CartRestored();
}

enum CartMessage {
  addedToCart,
  stockLimitReached,
  outOfStock,
  promoApplied,
  promoInvalid,
  promoExpired,
  promoUsed,
  promoBelowMinimum,
}

class CartState extends Equatable {
  const CartState({this.cart = const Cart(), this.message});

  final Cart cart;
  final CartMessage? message;

  CartState copyWith({Cart? cart, CartMessage? message}) =>
      CartState(cart: cart ?? this.cart, message: message);

  @override
  List<Object?> get props => [cart, message];
}

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

  @override
  void onChange(Change<CartState> change) {
    super.onChange(change);
    _persist(change.nextState);
  }

  final CartStore _store;
  final ProductRepository _products;
  final PromoRepository _promos;

  void _persist(CartState next) {
    _store.save([
      for (final line in next.cart.lines)
        (productId: line.product.id, quantity: line.quantity),
    ]);
  }

  Future<void> _onCleared(CartCleared e, Emitter<CartState> emit) async {
    emit(const CartState());
    await _store.clear();
  }

  Future<void> _onRestored(CartRestored e, Emitter<CartState> emit) async {
    final saved = _store.load();
    if (saved.isEmpty) return;

    final results = await Future.wait([
      for (final entry in saved) _products.byId(entry.productId),
    ]);

    // FIXED: Guard against state modification after bloc closes (§8.5)
    if (emit.isDone) return;

    final lines = <CartLine>[];
    for (var i = 0; i < saved.length; i++) {
      final product = results[i].valueOrNull;
      if (product == null || !product.inStock) continue;

      lines.add(
        CartLine(
          product: product,
          quantity: saved[i].quantity.clamp(1, product.stock),
        ),
      );
    }

    emit(CartState(cart: Cart(lines: lines)));
  }

  void _onAdded(CartItemAdded e, Emitter<CartState> emit) {
    if (!e.product.inStock) {
      emit(state.copyWith(message: CartMessage.outOfStock));
      return;
    }

    final lines = [...state.cart.lines];
    final index = lines.indexWhere((l) => l.product.id == e.product.id);

    final existing = index == -1 ? 0 : lines[index].quantity;
    final requested = existing + e.quantity;
    final granted = requested.clamp(1, e.product.stock);

    if (index == -1) {
      lines.add(CartLine(product: e.product, quantity: granted));
    } else {
      lines[index] = lines[index].copyWith(quantity: granted);
    }

    emit(
      CartState(
        cart: state.cart.copyWith(lines: lines),
        message: granted < requested
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
                l.copyWith(
                  quantity: l.product.inStock
                      ? e.quantity.clamp(1, l.product.stock)
                      : 1,
                )
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

    final result = await _promos.validate(
      code: code,
      subtotalMinor: state.cart.subtotalMinor,
      sellerId: state.cart.lines.firstOrNull?.product.sellerId ?? '',
    );

    // FIXED: Guard against state modification after bloc closes (§8.5)
    if (emit.isDone) return;

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
