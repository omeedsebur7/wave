import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/cart/domain/entities/cart.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';

Product _product({
  String id = 'p1',
  String sellerId = 's1',
  int price = 1000,
  int stock = 10,
}) =>
    Product(
      id: id,
      sellerId: sellerId,
      sellerName: 'Seller',
      title: 'Thing',
      description: '',
      priceMinor: price,
      currency: 'IQD',
      imageUrls: const [],
      stock: stock,
      createdAt: DateTime(2026),
    );

void main() {
  group('Cart totals', () {
    test('subtotal multiplies price by quantity', () {
      const cart = Cart();
      final withLines = cart.copyWith(
        lines: [
          CartLine(product: _product(price: 2500), quantity: 3),
        ],
      );
      expect(withLines.subtotalMinor, 7500);
    });

    test('a discount larger than the subtotal never produces a negative total', () {
      // A negative total reads as the shop paying the customer. Clamped.
      final cart = const Cart().copyWith(
        lines: [CartLine(product: _product(), quantity: 1)],
        discountMinor: 5000,
      );
      expect(cart.totalMinor, 0);
    });

    test('itemCount sums quantities, not lines', () {
      final cart = const Cart().copyWith(
        lines: [
          CartLine(product: _product(id: 'a'), quantity: 2),
          CartLine(product: _product(id: 'b'), quantity: 3),
        ],
      );
      expect(cart.itemCount, 5);
      expect(cart.lines.length, 2);
    });
  });

  group('Checkout eligibility', () {
    test('blocked when a line exceeds available stock', () {
      // The seller may have sold the last unit between add-to-cart and
      // checkout. Surface it here rather than failing at the server.
      final cart = const Cart().copyWith(
        lines: [CartLine(product: _product(stock: 2), quantity: 5)],
      );
      expect(cart.problemLines, hasLength(1));
      expect(cart.canCheckout, isFalse);
    });

    test('blocked when the cart spans multiple sellers', () {
      // v1 is single-seller per order — multi-seller needs split payouts and
      // split fulfilment, which is Phase 2.
      final cart = const Cart().copyWith(
        lines: [
          CartLine(product: _product(id: 'a'), quantity: 1),
          CartLine(product: _product(id: 'b', sellerId: 's2'), quantity: 1),
        ],
      );
      expect(cart.hasMultipleSellers, isTrue);
      expect(cart.canCheckout, isFalse);
    });

    test('blocked when empty', () {
      expect(const Cart().canCheckout, isFalse);
    });

    test('allowed for a single-seller in-stock cart', () {
      final cart = const Cart().copyWith(
        lines: [CartLine(product: _product(stock: 5), quantity: 2)],
      );
      expect(cart.canCheckout, isTrue);
    });
  });

  group('Product stock signals', () {
    test('low-stock threshold is a single business rule', () {
      expect(_product(stock: 5).isLowStock, isTrue);
      expect(_product(stock: 6).isLowStock, isFalse);
      // Out of stock is not "low stock" — they are different UI states.
      expect(_product(stock: 0).isLowStock, isFalse);
      expect(_product(stock: 0).inStock, isFalse);
    });
  });
}
