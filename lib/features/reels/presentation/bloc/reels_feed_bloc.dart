import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
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
  });

  final FeedStatus status;
  final List<Reel> reels;
  final int currentIndex;
  final bool hasMore;
  final Object? cursor;
  final Failure? failure;

  ReelsFeedState copyWith({
    FeedStatus? status,
    List<Reel>? reels,
    int? currentIndex,
    bool? hasMore,
    Object? cursor,
    Failure? failure,
    bool clearFailure = false,
  }) =>
      ReelsFeedState(
        status: status ?? this.status,
        reels: reels ?? this.reels,
        currentIndex: currentIndex ?? this.currentIndex,
        hasMore: hasMore ?? this.hasMore,
        cursor: cursor ?? this.cursor,
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [status, reels, currentIndex, hasMore, failure];
}

// ─── BLoC ────────────────────────────────────────────────────────────────
@injectable
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

  /// Drops Reels by blocked authors.
  ///
  /// Applied after the fetch, not in the query: Firestore's `whereNotIn` caps at
  /// ten values and cannot combine with the ordering the ranked feed needs. The
  /// cost is that a blocked author's Reel occupies a slot in the page — see the
  /// note on [BlockList].
  List<Reel> _visible(List<Reel> reels) =>
      reels.where((r) => !_blocks.isBlocked(r.authorId)).toList();

  /// Fallbacks only. The live values come from Remote Config, because the
  /// right page size depends on real network conditions in the target market
  /// — and finding that out is the whole reason it is a knob rather than a
  /// constant.
  static const defaultPageSize = 8; // 5–10 per §6
  static const defaultPrefetchThreshold = 3;

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
    (await _repo.fetchFeed(limit: pageSize)).fold(
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
      FeedRefreshed e, Emitter<ReelsFeedState> emit,) async {
    emit(const ReelsFeedState(status: FeedStatus.loading));
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
    (await _repo.fetchFeed(cursor: state.cursor, limit: pageSize)).fold(
      // A failed prefetch must not blow away the feed the user is watching —
      // stay ready, keep the existing list, let the next page change retry.
      (f) => emit(state.copyWith(status: FeedStatus.ready)),
      (page) => emit(
        state.copyWith(
          status: FeedStatus.ready,
          reels: [...state.reels, ..._visible(page.reels)],
          cursor: page.cursor,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> _onLikeToggled(
    ReelLikeToggled e,
    Emitter<ReelsFeedState> emit,
  ) async {
    final index = state.reels.indexWhere((r) => r.id == e.reelId);
    if (index == -1) return;
    final reel = state.reels[index];
    final nowLiked = !reel.likedByMe;

    // Optimistic: the heart fills instantly. A like that waits for a round-trip
    // feels broken even when it succeeds.
    emit(
      state.copyWith(
        reels: [...state.reels]
          ..[index] = reel.copyWith(
            likedByMe: nowLiked,
            likeCount: reel.likeCount + (nowLiked ? 1 : -1),
          ),
      ),
    );

    (nowLiked ? await _repo.like(e.reelId) : await _repo.unlike(e.reelId)).fold(
      (f) {
        // Roll back on failure rather than leaving a lie on screen.
        emit(
          state.copyWith(
            reels: [...state.reels]..[index] = reel,
            failure: f,
          ),
        );
      },
      (_) {},
    );
  }

  Future<void> _onSaveToggled(
    ReelSaveToggled e,
    Emitter<ReelsFeedState> emit,
  ) async {
    final index = state.reels.indexWhere((r) => r.id == e.reelId);
    if (index == -1) return;
    final reel = state.reels[index];
    final nowSaved = !reel.savedByMe;

    emit(
      state.copyWith(
        reels: [...state.reels]..[index] = reel.copyWith(savedByMe: nowSaved),
      ),
    );

    (await _repo.toggleSave(e.reelId, saved: nowSaved)).fold(
      (f) {
        emit(
          state.copyWith(
            reels: [...state.reels]..[index] = reel,
            failure: f,
          ),
        );
      },
      (_) {},
    );
  }
}
