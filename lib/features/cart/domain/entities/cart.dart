import 'package:equatable/equatable.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';

class CartLine extends Equatable {
  const CartLine({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  int get lineTotalMinor => product.priceMinor * quantity;

  /// A line can go stale between adding and checking out — the seller may sell
  /// the last unit to someone else. The cart surfaces this rather than letting
  /// checkout fail with a confusing server error.
  bool get exceedsStock => quantity > product.stock;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product.id, quantity];
}

class Cart extends Equatable {
  const Cart({this.lines = const [], this.promoCode, this.discountMinor = 0});

  final List<CartLine> lines;
  final String? promoCode;
  final int discountMinor;

  bool get isEmpty => lines.isEmpty;
  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);

  int get subtotalMinor => lines.fold(0, (sum, l) => sum + l.lineTotalMinor);

  /// Clamped at zero — a discount larger than the subtotal must never produce a
  /// negative total, which would read as the shop paying the customer.
  int get totalMinor =>
      (subtotalMinor - discountMinor).clamp(0, subtotalMinor);

  String get currency =>
      lines.isEmpty ? 'IQD' : lines.first.product.currency;

  /// v1 is single-seller per order (§5.1: one product per Reel; multi-seller
  /// carts need split payouts and split fulfilment, which is Phase 2).
  bool get hasMultipleSellers =>
      lines.map((l) => l.product.sellerId).toSet().length > 1;

  List<CartLine> get problemLines =>
      [for (final l in lines) if (l.exceedsStock || !l.product.inStock) l];

  bool get canCheckout =>
      lines.isNotEmpty && problemLines.isEmpty && !hasMultipleSellers;

  Cart copyWith({
    List<CartLine>? lines,
    String? promoCode,
    int? discountMinor,
    bool clearPromo = false,
  }) =>
      Cart(
        lines: lines ?? this.lines,
        promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
        discountMinor: clearPromo ? 0 : (discountMinor ?? this.discountMinor),
      );

  @override
  List<Object?> get props => [lines, promoCode, discountMinor];
}
