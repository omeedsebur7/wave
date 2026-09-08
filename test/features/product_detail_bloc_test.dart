import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';
import 'package:wave/features/marketplace/presentation/bloc/product_detail_bloc.dart';
import 'package:wave/features/reviews/domain/repositories/review_repository.dart';

class _MockProducts extends Mock implements ProductRepository {}

class _MockReviews extends Mock implements ReviewRepository {}

Product _product({int stock = 5}) => Product(
      id: 'p1',
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
  late _MockProducts products;
  late _MockReviews reviews;

  setUp(() {
    products = _MockProducts();
    reviews = _MockReviews();

    // Supplementary calls succeed unless a test says otherwise.
    when(() => reviews.forProduct(any()))
        .thenAnswer((_) async => const Success([]));
    when(() => reviews.summaryForProduct(any()))
        .thenAnswer((_) async => const Success(RatingSummary.empty));
  });

  ProductDetailBloc build() => ProductDetailBloc(products, reviews);

  group('cold load', () {
    blocTest<ProductDetailBloc, ProductDetailState>(
      'loading then ready',
      setUp: () => when(() => products.byId('p1'))
          .thenAnswer((_) async => Success(_product())),
      build: build,
      act: (b) => b.add(const ProductDetailRequested('p1')),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.ready)
            .having((s) => s.product, 'product', isNotNull),
      ],
    );

    // The deep-link case: a shared link to a deleted listing.
    blocTest<ProductDetailBloc, ProductDetailState>(
      'a missing product surfaces NotFoundFailure, not a generic error',
      setUp: () => when(() => products.byId('p1')).thenAnswer(
        (_) async => const Err(
          NotFoundFailure('Product not found', FailureReason.productNotFound),
        ),
      ),
      build: build,
      act: (b) => b.add(const ProductDetailRequested('p1')),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.failure)
            .having((s) => s.failure, 'failure', isA<NotFoundFailure>()),
      ],
    );

    // B2. byId catches only FirebaseException, so a malformed document throws
    // straight through. This used to leave the state on `loading` forever.
    blocTest<ProductDetailBloc, ProductDetailState>(
      'a throwing repository fails visibly instead of hanging on the skeleton',
      setUp: () => when(() => products.byId('p1'))
          .thenAnswer((_) async => throw TypeError()),
      build: build,
      act: (b) => b.add(const ProductDetailRequested('p1')),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.failure),
      ],
    );
  });

  group('preloaded', () {
    blocTest<ProductDetailBloc, ProductDetailState>(
      'paints immediately, never showing a loading state',
      setUp: () => when(() => products.byId('p1'))
          .thenAnswer((_) async => Success(_product(stock: 3))),
      build: build,
      act: (b) => b.add(ProductDetailRequested('p1', preloaded: _product())),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.ready),
        isA<ProductDetailState>()
            .having((s) => s.product?.stock, 'refreshed stock', 3),
      ],
      verify: (_) {
        // P4: content already in hand is never skeletoned over.
      },
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'a refresh failure keeps the preloaded product on screen',
      setUp: () => when(() => products.byId('p1'))
          .thenAnswer((_) async => const Err(NetworkFailure())),
      build: build,
      act: (b) => b.add(ProductDetailRequested('p1', preloaded: _product())),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.ready),
      ],
    );
  });

  group('retry', () {
    // B1. The retry emitted nothing before awaiting, so the error screen sat
    // there for the whole fetch and people tapped Retry repeatedly.
    blocTest<ProductDetailBloc, ProductDetailState>(
      'announces loading before refetching',
      setUp: () => when(() => products.byId('p1'))
          .thenAnswer((_) async => const Err(NetworkFailure())),
      build: build,
      seed: () => const ProductDetailState(
        status: ProductDetailStatus.failure,
        failure: NetworkFailure(),
      ),
      act: (b) => b.add(const ProductDetailRequested('p1')),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading)
            .having((s) => s.failure, 'failure cleared', isNull),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.failure),
      ],
    );

    // B3. `failure ?? this.failure` meant a failure survived every later
    // success, so a recovered screen still carried a stale error.
    blocTest<ProductDetailBloc, ProductDetailState>(
      'clears the previous failure once it succeeds',
      setUp: () => when(() => products.byId('p1'))
          .thenAnswer((_) async => Success(_product())),
      build: build,
      seed: () => const ProductDetailState(
        status: ProductDetailStatus.failure,
        failure: NetworkFailure(),
      ),
      act: (b) => b.add(const ProductDetailRequested('p1')),
      skip: 1,
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.ready)
            .having((s) => s.failure, 'failure', isNull),
      ],
    );
  });

  group('supplementary data', () {
    blocTest<ProductDetailBloc, ProductDetailState>(
      'a reviews failure does not break the page',
      setUp: () {
        when(() => products.byId('p1'))
            .thenAnswer((_) async => Success(_product()));
        when(() => reviews.forProduct(any()))
            .thenAnswer((_) async => const Err(NetworkFailure()));
      },
      build: build,
      act: (b) => b.add(const ProductDetailRequested('p1')),
      expect: () => [
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.loading),
        isA<ProductDetailState>()
            .having((s) => s.status, 'status', ProductDetailStatus.ready)
            .having((s) => s.reviews, 'reviews', isEmpty),
      ],
    );
  });
}
