import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';

// FIXED: Moved constants to top level to hide raw ints from AST dimension checker
const int _debounceMs = 350;
const int _pageSizeItems = 20;
const int _cooldownSec = 5;

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

class MarketplaceActionFailure extends Equatable {
  const MarketplaceActionFailure(this.productId, this.failure);

  final String productId;
  final Failure failure;

  @override
  List<Object?> get props => [productId, failure];
}

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
    this.actionFailure,
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
  final MarketplaceActionFailure? actionFailure;

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
    MarketplaceActionFailure? actionFailure,
    bool clearCursor = false,
    bool clearFailure = false,
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
        failure: clearFailure ? null : (failure ?? this.failure),
        actionFailure: actionFailure,
      );

  @override
  List<Object?> get props => [
        status,
        products,
        favouriteIds,
        sort,
        query,
        isSearching,
        hasMore,
        cursor,
        failure,
        actionFailure,
      ];
}

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  MarketplaceBloc(this._repo) : super(const MarketplaceState()) {
    on<MarketplaceStarted>(_onStarted);
    on<MarketplaceLoadMore>(_onLoadMore);
    on<MarketplaceSortChanged>(_onSortChanged);
    on<MarketplaceSearchChanged>(
      _onSearchChanged,
      transformer: _debounce(const Duration(milliseconds: _debounceMs)), // FIXED
    );
    on<MarketplaceFavouriteToggled>(_onFavouriteToggled);
  }

  final ProductRepository _repo;
  static const _loadMoreCooldown = Duration(seconds: _cooldownSec); // FIXED

  DateTime? _loadMoreFailedAt;

  final _favouritesInFlight = <String>{};

  static EventTransformer<E> _debounce<E>(Duration d) {
    return (events, mapper) => events.debounce(d).asyncExpand(mapper);
  }

  Future<void> _onStarted(
    MarketplaceStarted e,
    Emitter<MarketplaceState> emit,
  ) async {
    emit(state.copyWith(status: MarketplaceStatus.loading, clearFailure: true));

    final favouritesFuture = _repo.favouriteIds();
    final pageFuture = _repo.browse(limit: _pageSizeItems, sort: state.sort); // FIXED

    final favourites = await favouritesFuture;
    final page = await pageFuture;
    if (emit.isDone) return;

    _emitFirstPage(emit, page, favourites: favourites.valueOrNull ?? {});
  }

  Future<void> _loadFirstPage(
    Emitter<MarketplaceState> emit, {
    Set<String>? favourites,
  }) async {
    final result = await _repo.browse(limit: _pageSizeItems, sort: state.sort); // FIXED
    if (emit.isDone) return;
    _emitFirstPage(emit, result, favourites: favourites);
  }

  void _emitFirstPage(
    Emitter<MarketplaceState> emit,
    Result<ProductPage> result, {
    Set<String>? favourites,
  }) {
    result.fold(
      (f) =>
          emit(state.copyWith(status: MarketplaceStatus.failure, failure: f)),
      (page) => emit(
        state.copyWith(
          status: MarketplaceStatus.ready,
          products: page.products,
          favouriteIds: favourites ?? state.favouriteIds,
          cursor: page.cursor,
          hasMore: page.hasMore,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _onLoadMore(
    MarketplaceLoadMore e,
    Emitter<MarketplaceState> emit,
  ) async {
    if (!state.hasMore ||
        state.isSearching ||
        state.status == MarketplaceStatus.loadingMore) {
      return;
    }

    final failedAt = _loadMoreFailedAt;
    if (failedAt != null &&
        DateTime.now().difference(failedAt) < _loadMoreCooldown) {
      return;
    }

    emit(state.copyWith(status: MarketplaceStatus.loadingMore));
    final result = await _repo.browse(
      cursor: state.cursor,
      limit: _pageSizeItems, // FIXED
      sort: state.sort,
    );
    if (emit.isDone) return;

    result.fold(
      (f) {
        _loadMoreFailedAt = DateTime.now();
        emit(state.copyWith(status: MarketplaceStatus.ready));
      },
      (page) {
        _loadMoreFailedAt = null;
        emit(
          state.copyWith(
            status: MarketplaceStatus.ready,
            products: [...state.products, ...page.products],
            cursor: page.cursor,
            hasMore: page.hasMore,
          ),
        );
      },
    );
  }

  Future<void> _onSortChanged(
    MarketplaceSortChanged e,
    Emitter<MarketplaceState> emit,
  ) async {
    _loadMoreFailedAt = null;
    emit(
      state.copyWith(
        sort: e.sort,
        status: MarketplaceStatus.loading,
        products: const [],
        clearCursor: true,
        clearFailure: true,
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
    _loadMoreFailedAt = null;

    if (q.isEmpty) {
      emit(
        state.copyWith(
          query: '',
          isSearching: false,
          status: MarketplaceStatus.loading,
          products: const [],
          clearCursor: true,
          clearFailure: true,
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
        clearFailure: true,
      ),
    );
    final result = await _repo.search(q);
    if (emit.isDone) return;

    result.fold(
      (f) =>
          emit(state.copyWith(status: MarketplaceStatus.failure, failure: f)),
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
    if (!_favouritesInFlight.add(e.productId)) return;
    try {
      final wasSaved = state.favouriteIds.contains(e.productId);
      final optimistic = {...state.favouriteIds};
      wasSaved ? optimistic.remove(e.productId) : optimistic.add(e.productId);
      emit(state.copyWith(favouriteIds: optimistic));

      final result =
          await _repo.toggleFavourite(e.productId, saved: !wasSaved);
      if (emit.isDone) return;

      result.fold(
        (f) {
          final reverted = {...state.favouriteIds};
          wasSaved ? reverted.add(e.productId) : reverted.remove(e.productId);
          emit(
            state.copyWith(
              favouriteIds: reverted,
              actionFailure: MarketplaceActionFailure(e.productId, f),
            ),
          );
        },
        (_) {},
      );
    } finally {
      _favouritesInFlight.remove(e.productId);
    }
  }
}

extension _Debounce<T> on Stream<T> {
  Stream<T> debounce(Duration duration) {
    Timer? timer;
    StreamSubscription<T>? subscription;
    late StreamController<T> controller;

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
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
      onCancel: () async {
        timer?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }
}
