import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/config/remote_config_keys.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/services/block_list.dart';
import 'package:wave/core/services/remote_config_service.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';
import 'package:wave/features/reels/domain/repositories/reel_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────
sealed class ReelsFeedEvent extends Equatable {
  const ReelsFeedEvent();
  @override
  List<Object?> get props => [];
}

class FeedStarted extends ReelsFeedEvent {
  const FeedStarted();
}

class FeedRefreshed extends ReelsFeedEvent {
  const FeedRefreshed();
}

/// Emitted on every page change. The BLoC decides whether that's close enough
/// to the end to prefetch — the UI doesn't need to know the threshold.
class FeedPageChanged extends ReelsFeedEvent {
  const FeedPageChanged(this.index);
  final int index;
  @override
  List<Object?> get props => [index];
}

class ReelLikeToggled extends ReelsFeedEvent {
  const ReelLikeToggled(this.reelId);
  final String reelId;
  @override
  List<Object?> get props => [reelId];
}

class ReelSaveToggled extends ReelsFeedEvent {
  const ReelSaveToggled(this.reelId);
  final String reelId;
  @override
  List<Object?> get props => [reelId];
}

// ─── State ───────────────────────────────────────────────────────────────
enum FeedStatus { initial, loading, ready, loadingMore, failure }

class ReelsFeedState extends Equatable {
  const ReelsFeedState({
    this.status = FeedStatus.initial,
    this.reels = const [],
    this.currentIndex = 0,
    this.hasMore = true,
    this.cursor,
    this.failure,
    this.actionFailure,
  });

  final FeedStatus status;
  final List<Reel> reels;
  final int currentIndex;
  final bool hasMore;
  final Object? cursor;

  /// Sticky. Describes the whole feed being unusable, and pairs with
  /// [FeedStatus.failure]. Cleared explicitly via `clearFailure`.
  final Failure? failure;

  /// One-shot, for a SnackBar. A failed like must not blank a feed the user is
  /// happily watching — but it must not be silent either, which it was: the
  /// heart rolled back with no explanation and the failure sat in state
  /// unread. Assigned directly in copyWith so the next state clears it, the
  /// same shape as CartState.message.
  final Failure? actionFailure;

  ReelsFeedState copyWith({
    FeedStatus? status,
    List<Reel>? reels,
    int? currentIndex,
    bool? hasMore,
    Object? cursor,
    Failure? failure,
    Failure? actionFailure,
    bool clearFailure = false,
    bool clearCursor = false,
  }) =>
      ReelsFeedState(
        status: status ?? this.status,
        reels: reels ?? this.reels,
        currentIndex: currentIndex ?? this.currentIndex,
        hasMore: hasMore ?? this.hasMore,
        cursor: clearCursor ? null : (cursor ?? this.cursor),
        failure: clearFailure ? null : (failure ?? this.failure),
        actionFailure: actionFailure,
      );

  // cursor belongs here. Omitting it meant two states differing only by cursor
  // compared equal, so the emit was dropped and pagination silently refetched
  // the same page.
  @override
  List<Object?> get props =>
      [status, reels, currentIndex, hasMore, cursor, failure, actionFailure];
}

// ─── BLoC ────────────────────────────────────────────────────────────────

class ReelsFeedBloc extends Bloc<ReelsFeedEvent, ReelsFeedState> {
  ReelsFeedBloc(this._repo, this._analytics, this._config, this._blocks)
      : super(const ReelsFeedState()) {
    // Cascaded off explicit `this`, not off the return value of the first
    // `on<...>()` call — see the identical note in auth_bloc.dart, which is
    // where this exact mistake was made and caught: `on<T>()` returns void,
    // so a cascade has to start from an actual object reference.
    this
      ..on<FeedStarted>(_onStarted)
      ..on<FeedRefreshed>(_onRefreshed)
      ..on<FeedPageChanged>(_onPageChanged)
      ..on<ReelLikeToggled>(_onLikeToggled)
      ..on<ReelSaveToggled>(_onSaveToggled);
  }

  final ReelRepository _repo;
  final AnalyticsService _analytics;
  final RemoteConfigService _config;
  final BlockList _blocks;

  /// Reel ids with a like or save round trip in flight.
  ///
  /// Without this, double-tapping the heart runs two handlers concurrently:
  /// the second reads the already-toggled state, sends the opposite call, and
  /// the two rollbacks restore stale snapshots that drift the count. A
  /// `droppable()` transformer would do the same job but needs
  /// bloc_concurrency, which is a new dependency.
  final _inFlight = <String>{};

  /// Drops Reels by blocked authors.
  ///
  /// Applied after the fetch, not in the query: Firestore's `whereNotIn` caps
  /// at ten values and cannot combine with the ordering the ranked feed needs.
  List<Reel> _visible(List<Reel> reels) =>
      reels.where((r) => !_blocks.isBlocked(r.authorId)).toList();

  /// Fallbacks only. The live values come from Remote Config, because the
  /// right page size depends on real network conditions in the target market
  /// — and finding that out is the whole reason it is a knob rather than a
  /// constant.
  static const defaultPageSize = 8; // 5–10 per §6
  static const defaultPrefetchThreshold = 3;

  /// How many consecutive fully-blocked pages to skip before giving up.
  ///
  /// A page whose authors are all blocked adds nothing to the list. The list
  /// does not grow, the PageView cannot advance, no further FeedPageChanged is
  /// emitted — so nothing ever triggers another fetch and the feed dead-ends
  /// with hasMore still true. Bounded rather than a `while (true)` so a user
  /// who has blocked half the market does not spin through the collection.
  static const _maxBlockedPageSkips = 3;

  int get pageSize {
    final v = _config.getInt(RemoteConfigKeys.feedPageSize);
    // Clamped to the §6 range: a page of 1 makes scrolling stutter, and a page
    // of 100 defeats the point of pagination. A bad Remote Config value must
    // not be able to break the feed.
    return v == 0 ? defaultPageSize : v.clamp(5, 10);
  }

  int get prefetchThreshold {
    final v = _config.getInt(RemoteConfigKeys.feedPrefetchThreshold);
    return v == 0 ? defaultPrefetchThreshold : v.clamp(1, pageSize);
  }

  Future<void> _onStarted(FeedStarted e, Emitter<ReelsFeedState> emit) async {
    emit(state.copyWith(status: FeedStatus.loading, clearFailure: true));

    // Timed, because §6 asks for performance monitoring on the paths that
    // decide whether the app feels fast. A feed that takes two seconds to
    // first paint loses people before they have seen anything.
    final started = DateTime.now();
    final result = await _repo.fetchFeed(limit: pageSize);

    // The Reels page is a factory registration disposed on pop. Swiping away
    // mid-fetch used to emit into a closed bloc and throw StateError.
    if (emit.isDone) return;

    result.fold(
      (f) => emit(state.copyWith(status: FeedStatus.failure, failure: f)),
      (page) {
        unawaited(
          _analytics.log(
            AnalyticsEvents.feedPageLoaded,
            params: {
              AnalyticsParams.durationMs:
                  DateTime.now().difference(started).inMilliseconds,
              'count': page.reels.length,
              'page': 1,
            },
          ),
        );
        emit(
          state.copyWith(
            status: FeedStatus.ready,
            reels: _visible(page.reels),
            cursor: page.cursor,
            hasMore: page.hasMore,
          ),
        );
      },
    );
  }

  Future<void> _onRefreshed(
    FeedRefreshed e,
    Emitter<ReelsFeedState> emit,
  ) async {
    // Keeps the current reels on screen while refetching.
    //
    // This emitted `const ReelsFeedState(status: loading)`, whose `reels` is
    // a const empty list — so pull-to-refresh visibly emptied the feed,
    // including the video being watched, before refilling it. P4 asks for the
    // opposite: prefer cached content over a skeleton.
    //
    // The cursor and hasMore DO reset, because a refresh starts the pagination
    // over. Only the visible list is preserved.
    emit(
      state.copyWith(
        status: FeedStatus.loading,
        clearFailure: true,
        clearCursor: true,
        hasMore: true,
      ),
    );
    add(const FeedStarted());
  }

  Future<void> _onPageChanged(
    FeedPageChanged e,
    Emitter<ReelsFeedState> emit,
  ) async {
    emit(state.copyWith(currentIndex: e.index));

    if (e.index < state.reels.length) {
      final reel = state.reels[e.index];
      unawaited(_repo.recordView(reel.id));
      unawaited(
        _analytics.log(
          AnalyticsEvents.reelViewed,
          params: {
            AnalyticsParams.reelId: reel.id,
            AnalyticsParams.sellerId: reel.authorId,
          },
        ),
      );
    }

    // Prefetch before the user reaches the end so scrolling never visibly
    // stalls (§6).
    final nearEnd = e.index >= state.reels.length - prefetchThreshold;
    if (!nearEnd || !state.hasMore || state.status == FeedStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: FeedStatus.loadingMore));

    var cursor = state.cursor;
    var hasMore = state.hasMore;
    final gathered = <Reel>[];

    // Keeps pulling while a page comes back entirely blocked. See
    // _maxBlockedPageSkips.
    for (var attempt = 0;
        attempt < _maxBlockedPageSkips && hasMore && gathered.isEmpty;
        attempt++) {
      final result = await _repo.fetchFeed(cursor: cursor, limit: pageSize);
      if (emit.isDone) return;

      final page = result.valueOrNull;
      if (page == null) {
        // A failed prefetch must not blow away the feed the user is watching —
        // stay ready, keep the existing list, let the next page change retry.
        emit(state.copyWith(status: FeedStatus.ready));
        return;
      }

      gathered.addAll(_visible(page.reels));
      cursor = page.cursor;
      hasMore = page.hasMore;
    }

    if (emit.isDone) return;
    emit(
      state.copyWith(
        status: FeedStatus.ready,
        reels: [...state.reels, ...gathered],
        cursor: cursor,
        hasMore: hasMore,
      ),
    );
  }

  Future<void> _onLikeToggled(
    ReelLikeToggled e,
    Emitter<ReelsFeedState> emit,
  ) async {
    if (!_inFlight.add(e.reelId)) return;
    try {
      final index = state.reels.indexWhere((r) => r.id == e.reelId);
      if (index == -1) return;
      final reel = state.reels[index];
      final nowLiked = !reel.likedByMe;

      // Optimistic: the heart fills instantly. A like that waits for a
      // round-trip feels broken even when it succeeds.
      emit(
        state.copyWith(
          reels: [...state.reels]
            ..[index] = reel.copyWith(
              likedByMe: nowLiked,
              likeCount: reel.likeCount + (nowLiked ? 1 : -1),
            ),
        ),
      );

      final result =
          nowLiked ? await _repo.like(e.reelId) : await _repo.unlike(e.reelId);
      if (emit.isDone) return;

      result.fold(
        (f) => _rollback(
          emit,
          e.reelId,
          f,
          (r) => r.copyWith(
            likedByMe: !nowLiked,
            likeCount: r.likeCount + (nowLiked ? -1 : 1),
          ),
        ),
        (_) {},
      );
    } finally {
      _inFlight.remove(e.reelId);
    }
  }

  Future<void> _onSaveToggled(
    ReelSaveToggled e,
    Emitter<ReelsFeedState> emit,
  ) async {
    if (!_inFlight.add(e.reelId)) return;
    try {
      final index = state.reels.indexWhere((r) => r.id == e.reelId);
      if (index == -1) return;
      final reel = state.reels[index];
      final nowSaved = !reel.savedByMe;

      emit(
        state.copyWith(
          reels: [...state.reels]..[index] = reel.copyWith(savedByMe: nowSaved),
        ),
      );

      final result = await _repo.toggleSave(e.reelId, saved: nowSaved);
      if (emit.isDone) return;

      result.fold(
        (f) => _rollback(
          emit,
          e.reelId,
          f,
          (r) => r.copyWith(savedByMe: !nowSaved),
        ),
        (_) {},
      );
    } finally {
      _inFlight.remove(e.reelId);
    }
  }

  /// Undoes an optimistic change after the round trip failed.
  ///
  /// Re-finds by id rather than reusing the index captured before the await. A
  /// refresh during the round trip replaces the list, at which point the old
  /// index points at a different reel — or past the end, which throws
  /// RangeError. That was a live crash on any like that overlapped a refresh.
  ///
  /// Applies the inverse delta rather than restoring the pre-toggle snapshot,
  /// so a count that moved for other reasons during the round trip is not
  /// clobbered.
  void _rollback(
    Emitter<ReelsFeedState> emit,
    String reelId,
    Failure failure,
    Reel Function(Reel) undo,
  ) {
    final index = state.reels.indexWhere((r) => r.id == reelId);
    if (index == -1) {
      emit(state.copyWith(actionFailure: failure));
      return;
    }
    emit(
      state.copyWith(
        reels: [...state.reels]..[index] = undo(state.reels[index]),
        actionFailure: failure,
      ),
    );
  }
}
