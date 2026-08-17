import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';

sealed class MarketplaceEvent extends Equatable {
  const MarketplaceEvent();
  @override
  List<Object?> get props => [];
}

class MarketplaceStarted extends MarketplaceEvent {
  const MarketplaceStarted();
}

class MarketplaceLoadMore extends MarketplaceEvent {
  const MarketplaceLoadMore();
}

class MarketplaceSortChanged extends MarketplaceEvent {
  const MarketplaceSortChanged(this.sort);
  final ProductSort sort;
  @override
  List<Object?> get props => [sort];
}

class MarketplaceSearchChanged extends MarketplaceEvent {
  const MarketplaceSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class MarketplaceFavouriteToggled extends MarketplaceEvent {
  const MarketplaceFavouriteToggled(this.productId);
  final String productId;
  @override
  List<Object?> get props => [productId];
}

enum MarketplaceStatus { initial, loading, ready, loadingMore, failure }

class MarketplaceState extends Equatable {
  const MarketplaceState({
    this.status = MarketplaceStatus.initial,
    this.products = const [],
    this.favouriteIds = const {},
    this.sort = ProductSort.newest,
    this.query = '',
    this.isSearching = false,
    this.hasMore = true,
    this.cursor,
    this.failure,
  });

  final MarketplaceStatus status;
  final List<Product> products;
  final Set<String> favouriteIds;
  final ProductSort sort;
  final String query;
  final bool isSearching;
  final bool hasMore;
  final Object? cursor;
  final Failure? failure;

  MarketplaceState copyWith({
    MarketplaceStatus? status,
    List<Product>? products,
    Set<String>? favouriteIds,
    ProductSort? sort,
    String? query,
    bool? isSearching,
    bool? hasMore,
    Object? cursor,
    Failure? failure,
    bool clearCursor = false,
  }) =>
      MarketplaceState(
        status: status ?? this.status,
        products: products ?? this.products,
        favouriteIds: favouriteIds ?? this.favouriteIds,
        sort: sort ?? this.sort,
        query: query ?? this.query,
        isSearching: isSearching ?? this.isSearching,
        hasMore: hasMore ?? this.hasMore,
        cursor: clearCursor ? null : (cursor ?? this.cursor),
        failure: failure,
      );

  @override
  List<Object?> get props =>
      [status, products, favouriteIds, sort, query, isSearching, hasMore];
}

@injectable
class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  MarketplaceBloc(this._repo) : super(const MarketplaceState()) {
    on<MarketplaceStarted>(_onStarted);
    on<MarketplaceLoadMore>(_onLoadMore);
    on<MarketplaceSortChanged>(_onSortChanged);
    // Debounced: a search that fires a Firestore query per keystroke is a
    // query bill proportional to typing speed.
    on<MarketplaceSearchChanged>(
      _onSearchChanged,
      transformer: _debounce(const Duration(milliseconds: 350)),
    );
    on<MarketplaceFavouriteToggled>(_onFavouriteToggled);
  }

  final ProductRepository _repo;
  static const _pageSize = 20;

  static EventTransformer<E> _debounce<E>(Duration d) {
    return (events, mapper) =>
        events.debounce(d).asyncExpand(mapper);
  }

  Future<void> _onStarted(
    MarketplaceStarted e,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(state.copyWith(status: MarketplaceStatus.loading));
    final favourites = await _repo.favouriteIds();
    await _loadFirstPage(emit, favourites: favourites.valueOrNull ?? {});
  }

  Future<void> _loadFirstPage(
    Emitter<MarketplaceState> emit, {
    Set<String>? favourites,
  }) async {
    final result =
        await _repo.browse(limit: _pageSize, sort: state.sort);
    result.fold(
      (f) => emit(
        state.copyWith(status: MarketplaceStatus.failure, failure: f),
      ),
      (page) => emit(
        state.copyWith(
          status: MarketplaceStatus.ready,
          products: page.products,
          favouriteIds: favourites ?? state.favouriteIds,
          cursor: page.cursor,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    MarketplaceLoadMore e,
    Emitter<MarketplaceState> emit,
  ) async {
    // Searching returns a single unpaginated result set — no infinite scroll
    // while a query is active.
    if (!state.hasMore ||
        state.isSearching ||
        state.status == MarketplaceStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: MarketplaceStatus.loadingMore));
    final result = await _repo.browse(
      cursor: state.cursor,
      limit: _pageSize,
      sort: state.sort,
    );
    result.fold(
      // A failed page-2 fetch must not clear page 1.
      (f) => emit(state.copyWith(status: MarketplaceStatus.ready)),
      (page) => emit(
        state.copyWith(
          status: MarketplaceStatus.ready,
          products: [...state.products, ...page.products],
          cursor: page.cursor,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onSortChanged(
    MarketplaceSortChanged e,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(
      state.copyWith(
        sort: e.sort,
        status: MarketplaceStatus.loading,
        products: const [],
        clearCursor: true,
        hasMore: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onSearchChanged(
    MarketplaceSearchChanged e,
    Emitter<MarketplaceState> emit,
  ) async {
    final q = e.query.trim();

    if (q.isEmpty) {
      emit(
        state.copyWith(
          query: '',
          isSearching: false,
          status: MarketplaceStatus.loading,
          products: const [],
          clearCursor: true,
          hasMore: true,
        ),
      );
      await _loadFirstPage(emit);
      return;
    }

    emit(
      state.copyWith(
        query: q,
        isSearching: true,
        status: MarketplaceStatus.loading,
      ),
    );
    final result = await _repo.search(q);
    result.fold(
      (f) => emit(
        state.copyWith(status: MarketplaceStatus.failure, failure: f),
      ),
      (products) => emit(
        state.copyWith(
          status: MarketplaceStatus.ready,
          products: products,
          hasMore: false,
        ),
      ),
    );
  }

  Future<void> _onFavouriteToggled(
    MarketplaceFavouriteToggled e,
    Emitter<MarketplaceState> emit,
  ) async {
    final wasSaved = state.favouriteIds.contains(e.productId);
    final optimistic = {...state.favouriteIds};
    wasSaved ? optimistic.remove(e.productId) : optimistic.add(e.productId);
    emit(state.copyWith(favouriteIds: optimistic));

    final result =
        await _repo.toggleFavourite(e.productId, saved: !wasSaved);
    result.fold(
      (f) {
        final reverted = {...state.favouriteIds};
        wasSaved ? reverted.add(e.productId) : reverted.remove(e.productId);
        emit(state.copyWith(favouriteIds: reverted, failure: f));
      },
      (_) {},
    );
  }
}

/// Minimal debounce so the BLoC doesn't need a bloc_concurrency dependency for
/// one transformer.
extension _Debounce<T> on Stream<T> {
  Stream<T> debounce(Duration duration) {
    Timer? timer;
    late StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        listen(
          (event) {
            timer?.cancel();
            timer = Timer(duration, () => controller.add(event));
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
      },
      onCancel: () => timer?.cancel(),
    );
    return controller.stream;
  }
}
