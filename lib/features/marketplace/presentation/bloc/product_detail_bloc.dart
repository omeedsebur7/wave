import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/marketplace/data/repositories/product_repository_impl.dart' show ProductRepositoryImpl;
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';
import 'package:wave/features/reviews/domain/entities/review.dart';
import 'package:wave/features/reviews/domain/repositories/review_repository.dart';

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();
  @override
  List<Object?> get props => [];
}

class ProductDetailRequested extends ProductDetailEvent {
  const ProductDetailRequested(this.productId, {this.preloaded});

  final String productId;

  /// Passed through from the grid when we already have it, so the page paints
  /// immediately instead of flashing a skeleton for data the previous screen
  /// was already holding.
  final Product? preloaded;

  // `preloaded` belongs here. Two events that differ compared equal before,
  // which is wrong on its own and makes bloc_test's `expect` unable to tell a
  // cold request from a warm one.
  @override
  List<Object?> get props => [productId, preloaded];
}

enum ProductDetailStatus { loading, ready, failure }

class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = ProductDetailStatus.loading,
    this.product,
    this.reviews = const [],
    this.summary = RatingSummary.empty,
    this.failure,
  });

  final ProductDetailStatus status;
  final Product? product;
  final List<Review> reviews;
  final RatingSummary summary;
  final Failure? failure;

  /// [clearFailure] exists because `failure ?? this.failure` can never write
  /// null: once a failure was set it survived every subsequent successful
  /// emit, forever. Harmless while the UI only read `status`, and not harmless
  /// at all now that the failure decides which error screen to show.
  ProductDetailState copyWith({
    ProductDetailStatus? status,
    Product? product,
    List<Review>? reviews,
    RatingSummary? summary,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      ProductDetailState(
        status: status ?? this.status,
        product: product ?? this.product,
        reviews: reviews ?? this.reviews,
        summary: summary ?? this.summary,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [status, product, reviews, summary, failure];
}

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc(this._products, this._reviews)
      : super(const ProductDetailState()) {
    on<ProductDetailRequested>(_onRequested);
  }

  final ProductRepository _products;
  final ReviewRepository _reviews;

  Future<void> _onRequested(
    ProductDetailRequested e,
    Emitter<ProductDetailState> emit,
  ) async {
    if (e.preloaded != null) {
      // Show what we have, then refresh underneath. Stock and price may have
      // moved since the grid was loaded, and stale stock is what turns into a
      // failed checkout later.
      emit(
        state.copyWith(
          status: ProductDetailStatus.ready,
          product: e.preloaded,
          clearFailure: true,
        ),
      );
    } else {
      // Announce the work before doing it.
      //
      // Retry used to emit nothing here, so the screen sat on its error state
      // for the entire fetch: you tapped Retry, nothing moved, you tapped it
      // again, and each tap fired another three requests. §3 calls this a dead
      // moment and it was the worst one in the app.
      emit(
        state.copyWith(
          status: ProductDetailStatus.loading,
          clearFailure: true,
        ),
      );
    }

    // Still fired in parallel — the three calls are independent and
    // serialising them doubles the time to a complete page for no reason —
    // but no longer through Future.wait over a single List.
    //
    // Future.wait<T> needs one T for the whole list, and the three calls here
    // return three DIFFERENT Result<T> specialisations. The only common type
    // Dart could infer was Future<Object>, which made every `.fold()` below an
    // unchecked dynamic call.
    final productFuture = _guard(_products.byId(e.productId), 'byId');
    final reviewsFuture = _guard(_reviews.forProduct(e.productId), 'reviews');
    final summaryFuture = _guard(
      _reviews.summaryForProduct(e.productId),
      'summary',
    );

    final productResult = await productFuture;
    final reviewsResult = await reviewsFuture;
    final summaryResult = await summaryFuture;

    // The page can be popped mid-fetch. Emitting into a closed bloc throws a
    // StateError, and this bloc is a factory registration disposed on pop, so
    // backing out of a slow product page hit it every time.
    if (emit.isDone) return;

    productResult.fold(
      (Failure f) {
        // A refresh failure with data already on screen is not worth blanking
        // the page for — keep showing the preloaded product.
        if (state.product == null) {
          emit(state.copyWith(status: ProductDetailStatus.failure, failure: f));
        }
      },
      (Product p) => emit(
        state.copyWith(
          status: ProductDetailStatus.ready,
          product: p,
          clearFailure: true,
        ),
      ),
    );

    // Reviews and the rating summary are supplementary. If either fails the
    // page is still useful — you can read the description, see the price and
    // buy. Surfacing an error banner over a working product page would be a
    // worse outcome than quietly showing no reviews.
    if (emit.isDone) return;
    reviewsResult.fold(
      (Failure _) {},
      (List<Review> r) => emit(state.copyWith(reviews: r)),
    );

    if (emit.isDone) return;
    summaryResult.fold(
      (Failure _) {},
      (RatingSummary s) => emit(state.copyWith(summary: s)),
    );
  }

  /// Converts a thrown exception into an [Err], so one bad response cannot
  /// take down the handler.
  ///
  /// [ProductRepositoryImpl.byId] catches only FirebaseException. A malformed
  /// document throws a TypeError out of ProductDto.fromDoc and straight past
  /// the repository — which used to throw out of this handler with the state
  /// still `loading`, so the screen showed a skeleton forever, and left the
  /// other two futures unawaited, surfacing as unhandled async errors.
  ///
  /// The repository is still the right place to catch these; this is the belt
  /// to that braces, because a data layer that throws is not a hypothetical.
  static Future<Result<T>> _guard<T>(Future<Result<T>> future, String tag) async {
    try {
      return await future;
    } catch (error, stack) {
      developer.log(
        'ProductDetailBloc.$tag threw instead of returning a Result',
        error: error,
        stackTrace: stack,
        name: 'wave.marketplace',
      );
      return Err(
        ServerFailure('Unexpected error in $tag', code: 'unhandled'),
      );
    }
  }
}
