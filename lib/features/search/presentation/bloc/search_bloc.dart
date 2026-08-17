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

/// Unified search across Products and Reels (§4).
///
/// Both are queried in parallel and rendered in one result set, because a buyer
/// searching "leather bag" does not care whether the match came from a listing
/// title or a Reel caption — they care about finding the bag.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._products, this._reels, this._blocks)
      : super(const SearchState()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      // A Firestore query per keystroke is a bill proportional to typing speed.
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

    // Two characters is the shortest query worth spending a read on — a
    // single-letter prefix matches most of the catalogue and tells nobody
    // anything.
    if (q.length < 2) {
      emit(state.copyWith(query: q, status: SearchStatus.idle));
      return;
    }

    emit(state.copyWith(query: q, status: SearchStatus.searching));

    // Started before either is awaited, so the two round trips overlap. Two
    // sequential awaits would suspend before the second call was even issued,
    // making every search cost the SUM of both queries rather than the max —
    // which is not what the class doc above promises.
    final productsFuture = _products.search(q);
    final reelsFuture = _reels.search(q);

    final productsResult = await productsFuture;
    final reelsResult = await reelsFuture;

    final products = productsResult.valueOrNull;
    final reels = reelsResult.valueOrNull;

    // A stale response from a query the user has since changed must not
    // overwrite the current one.
    //
    // Not dead code, though it looks it: `asyncExpand` serialises
    // SearchQueryChanged handlers, so a newer query cannot land here mid-flight.
    // But SearchCleared is a separate `on<>` subscription, and different event
    // types DO run concurrently — a clear arriving while these two queries are
    // in flight resets state.query to '', and this guard is what stops the
    // completed search from repopulating a screen the user just emptied.
    if (state.query != q) return;

    emit(
      state.copyWith(
        status: SearchStatus.ready,
        // Search has to respect a block as much as the feed does. Someone who
        // blocked a seller and then found their listing by searching would
        // reasonably conclude the block did nothing.
        //
        // The fallbacks are explicitly typed. A bare `const []` infers as
        // List<dynamic>, the `??` widens to List<dynamic> via least upper
        // bound, and the enclosing literal's context type does not propagate
        // into a for-in iterable — so `p` and `r` would silently become
        // dynamic and the whole filter would go unchecked.
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
        // Held so onCancel can actually tear the source down. Without this the
        // timer was cancelled but the upstream subscription stayed open,
        // leaking one listener per bloc close.
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