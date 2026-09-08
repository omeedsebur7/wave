import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wave/core/services/block_list.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';
import 'package:wave/features/reels/domain/repositories/reel_repository.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}

enum SearchStatus { idle, searching, ready }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.products = const [],
    this.reels = const [],
  });

  final SearchStatus status;
  final String query;
  final List<Product> products;
  final List<Reel> reels;

  bool get hasResults => products.isNotEmpty || reels.isNotEmpty;
  int get totalCount => products.length + reels.length;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Product>? products,
    List<Reel>? reels,
  }) =>
      SearchState(
        status: status ?? this.status,
        query: query ?? this.query,
        products: products ?? this.products,
        reels: reels ?? this.reels,
      );

  @override
  List<Object?> get props => [status, query, products, reels];
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._products, this._reels, this._blocks)
      : super(const SearchState()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: (events, mapper) =>
          events.debounce(const Duration(milliseconds: 350)).asyncExpand(mapper),
    );
    on<SearchCleared>((_, emit) => emit(const SearchState()));
  }

  final ProductRepository _products;
  final ReelRepository _reels;
  final BlockList _blocks;

  Future<void> _onQueryChanged(
    SearchQueryChanged e,
    Emitter<SearchState> emit,
  ) async {
    final q = e.query.trim();
    if (q.isEmpty) {
      emit(const SearchState());
      return;
    }

    if (q.length < 2) {
      emit(state.copyWith(query: q, status: SearchStatus.idle));
      return;
    }

    emit(state.copyWith(query: q, status: SearchStatus.searching));

    final productsFuture = _products.search(q);
    final reelsFuture = _reels.search(q);

    final productsResult = await productsFuture;
    final reelsResult = await reelsFuture;

    // FIXED: Guard against state modification after bloc closes (§8.5)
    if (emit.isDone) return;

    final products = productsResult.valueOrNull;
    final reels = reelsResult.valueOrNull;

    if (state.query != q) return;

    emit(
      state.copyWith(
        status: SearchStatus.ready,
        products: [
          for (final p in products ?? const <Product>[])
            if (!_blocks.isBlocked(p.sellerId)) p,
        ],
        reels: [
          for (final r in reels ?? const <Reel>[])
            if (!_blocks.isBlocked(r.authorId)) r,
        ],
      ),
    );
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
