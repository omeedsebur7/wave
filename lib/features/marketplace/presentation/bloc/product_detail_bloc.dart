import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wave/core/error/failures.dart';
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
  @override
  List<Object?> get props => [productId];
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

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    Product? product,
    List<Review>? reviews,
    RatingSummary? summary,
    Failure? failure,
  }) =>
      ProductDetailState(
        status: status ?? this.status,
        product: product ?? this.product,
        reviews: reviews ?? this.reviews,
        summary: summary ?? this.summary,
        failure: failure ?? this.failure,
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
        ),
      );
    }

    // Both requests in parallel: they are independent, and serialising them
    // doubles the time to a complete page for no reason.
    final results = await Future.wait([
      _products.byId(e.productId),
      _reviews.forProduct(e.productId),
      _reviews.summaryForProduct(e.productId),
    ]);

    final productResult = results[0] as dynamic;
    final reviewsResult = results[1] as dynamic;
    final summaryResult = results[2] as dynamic;

    productResult.fold(
      (Failure f) {
        // A refresh failure with data already on screen is not worth blanking
        // the page for — keep showing the preloaded product.
        if (state.product == null) {
          emit(state.copyWith(status: ProductDetailStatus.failure, failure: f));
        }
      },
      (Product p) => emit(
        state.copyWith(status: ProductDetailStatus.ready, product: p),
      ),
    );

    // Reviews and the rating summary are supplementary. If either fails the
    // page is still useful — you can read the description, see the price and
    // buy. Surfacing an error banner over a working product page would be a
    // worse outcome than quietly showing no reviews.
    reviewsResult.fold(
      (Failure _) {},
      (List<Review> r) => emit(state.copyWith(reviews: r)),
    );

    summaryResult.fold(
      (Failure _) {},
      (RatingSummary s) => emit(state.copyWith(summary: s)),
    );
  }
}
