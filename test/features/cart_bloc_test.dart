import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/cart/data/cart_store.dart';
import 'package:wave/features/cart/data/promo_repository.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';

class _MockStore extends Mock implements CartStore {}

class _MockProducts extends Mock implements ProductRepository {}

class _MockPromos extends Mock implements PromoRepository {}

Product _product({String id = 'p1', int stock = 5}) => Product(
      id: id,
      sellerId: 's1',
      sellerName: 'Test seller',
      title: 'Test product',
      description: 'Description',
      priceMinor: 15000,
      currency: 'IQD',
      imageUrls: const [],
      stock: stock,
      createdAt: DateTime.utc(2026),
    );

void main() {
  late _MockStore store;
  late _MockProducts products;
  late _MockPromos promos;

  setUp(() {
    store = _MockStore();
    products = _MockProducts();
    promos = _MockPromos();

    when(() => store.load()).thenReturn([]);
    when(() => store.save(any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
  });

  CartBloc build() => CartBloc(store, products, promos);

  group('adding', () {
    blocTest<CartBloc, CartState>(
      'adds a line and confirms with the same words the button used',
      build: build,
      act: (b) => b.add(CartItemAdded(_product())),
      expect: () => [
        isA<CartState>()
            .having((s) => s.cart.lines.length, 'lines', 1)
            .having((s) => s.message, 'message', CartMessage.addedToCart),
      ],
    );

    blocTest<CartBloc, CartState>(
      'a second add bumps quantity instead of adding a second line',
      build: build,
      act: (b) => b
        ..add(CartItemAdded(_product(), quantity: 2))
        ..add(CartItemAdded(_product())),
      skip: 1,
      expect: () => [
        isA<CartState>()
            .having((s) => s.cart.lines.length, 'lines', 1)
            .having((s) => s.cart.lines.first.quantity, 'quantity', 3),
      ],
    );

    // C2. This compared the resulting quantity to stock, so taking the last
    // unit reported a limit error for an add that fully succeeded.
    blocTest<CartBloc, CartState>(
      'taking the last unit still says added, not limit reached',
      build: build,
      act: (b) => b.add(CartItemAdded(_product(), quantity: 5)),
      expect: () => [
        isA<CartState>()
            .having((s) => s.cart.lines.first.quantity, 'quantity', 5)
            .having((s) => s.message, 'message', CartMessage.addedToCart),
      ],
    );

    blocTest<CartBloc, CartState>(
      'reports the limit only when the request was actually cut down',
      build: build,
      act: (b) => b.add(CartItemAdded(_product(stock: 3), quantity: 10)),
      expect: () => [
        isA<CartState>()
            .having((s) => s.cart.lines.first.quantity, 'quantity', 3)
            .having(
              (s) => s.message,
              'message',
              CartMessage.stockLimitReached,
            ),
      ],
    );

    // C1. `quantity.clamp(1, 0)` throws ArgumentError. The PDP happens to
    // check inStock first; nothing in the BLoC required it, and Reels Buy Now
    // does not go through the PDP.
    blocTest<CartBloc, CartState>(
      'adding an out-of-stock product does not throw',
      build: build,
      act: (b) => b.add(CartItemAdded(_product(stock: 0))),
      expect: () => [
        isA<CartState>()
            .having((s) => s.cart.lines, 'lines', isEmpty)
            .having((s) => s.message, 'message', CartMessage.outOfStock),
      ],
      errors: () => <dynamic>[],
    );
  });

  group('restore', () {
    // C3. This awaited inside the loop, so a ten-line cart cost ten sequential
    // round trips before the first frame.
    blocTest<CartBloc, CartState>(
      'refetches every saved line in parallel',
      setUp: () {
        when(() => store.load()).thenReturn([
          (productId: 'p1', quantity: 2),
          (productId: 'p2', quantity: 1),
        ]);
        when(() => products.byId('p1'))
            .thenAnswer((_) async => Success(_product()));
        when(() => products.byId('p2'))
            .thenAnswer((_) async => Success(_product(id: 'p2')));
      },
      build: build,
      act: (b) => b.add(const CartRestored()),
      expect: () => [
        isA<CartState>().having((s) => s.cart.lines.length, 'lines', 2),
      ],
    );

    blocTest<CartBloc, CartState>(
      'drops lines whose product sold out while the app was closed',
      setUp: () {
        when(() => store.load()).thenReturn([
          (productId: 'p1', quantity: 2),
          (productId: 'p2', quantity: 1),
        ]);
        when(() => products.byId('p1'))
            .thenAnswer((_) async => Success(_product()));
        when(() => products.byId('p2'))
            .thenAnswer((_) async => Success(_product(id: 'p2', stock: 0)));
      },
      build: build,
      act: (b) => b.add(const CartRestored()),
      expect: () => [
        isA<CartState>()
            .having((s) => s.cart.lines.length, 'lines', 1)
            .having((s) => s.cart.lines.first.product.id, 'kept', 'p1'),
      ],
    );

    blocTest<CartBloc, CartState>(
      'clamps a saved quantity down to current stock',
      setUp: () {
        when(() => store.load())
            .thenReturn([(productId: 'p1', quantity: 9)]);
        when(() => products.byId('p1'))
            .thenAnswer((_) async => Success(_product(stock: 2)));
      },
      build: build,
      act: (b) => b.add(const CartRestored()),
      expect: () => [
        isA<CartState>()
            .having((s) => s.cart.lines.first.quantity, 'quantity', 2),
      ],
    );
  });

  group('messages are one-shot', () {
    blocTest<CartBloc, CartState>(
      'a later change clears the previous message',
      build: build,
      act: (b) => b
        ..add(CartItemAdded(_product()))
        ..add(const CartItemRemoved('p1')),
      expect: () => [
        isA<CartState>()
            .having((s) => s.message, 'message', CartMessage.addedToCart),
        isA<CartState>().having((s) => s.message, 'cleared', isNull),
      ],
    );
  });
}
