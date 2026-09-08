import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/services/block_list.dart';
import 'package:wave/core/services/remote_config_service.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';
import 'package:wave/features/reels/domain/repositories/reel_repository.dart';
import 'package:wave/features/reels/presentation/bloc/reels_feed_bloc.dart';

class _MockRepo extends Mock implements ReelRepository {}

class _MockAnalytics extends Mock implements AnalyticsService {}

class _MockConfig extends Mock implements RemoteConfigService {}

class _MockBlocks extends Mock implements BlockList {}

// Adjust to the real Reel constructor — these are the fields the BLoC touches.
Reel _reel(String id, {String authorId = 'a1', bool liked = false, int likes = 0}) =>
    Reel(
      id: id,
      authorId: authorId,
      authorName: 'Author $authorId',
      bunnyVideoId: 'video_$id',
      caption: 'Caption for $id',
      createdAt: DateTime(2026),
      durationSeconds: 15,
      thumbnailUrl: 'https://example.com/thumb_$id.jpg',
      likedByMe: liked,
      likeCount: likes,
    );

void main() {
  late _MockRepo repo;
  late _MockAnalytics analytics;
  late _MockConfig config;
  late _MockBlocks blocks;

  setUp(() {
    repo = _MockRepo();
    analytics = _MockAnalytics();
    config = _MockConfig();
    blocks = _MockBlocks();

    when(() => config.getInt(any())).thenReturn(0); // fall back to defaults
    when(() => blocks.isBlocked(any())).thenReturn(false);
    when(() => analytics.log(any(), params: any(named: 'params')))
        .thenAnswer((_) async {});
    when(() => repo.recordView(any())).thenAnswer((_) async => const Success(null));
    when(() => repo.like(any())).thenAnswer((_) async => const Success(null));
    when(() => repo.unlike(any())).thenAnswer((_) async => const Success(null));
  });

  ReelsFeedBloc build() => ReelsFeedBloc(repo, analytics, config, blocks);

  group('like', () {
    blocTest<ReelsFeedBloc, ReelsFeedState>(
      'fills the heart immediately, before the round trip resolves',
      setUp: () => when(() => repo.like('r1'))
          .thenAnswer((_) async => const Success(null)),
      build: build,
      seed: () => ReelsFeedState(
        status: FeedStatus.ready,
        reels: [_reel('r1')],
      ),
      act: (b) => b.add(const ReelLikeToggled('r1')),
      expect: () => [
        isA<ReelsFeedState>()
            .having((s) => s.reels.first.likedByMe, 'liked', true)
            .having((s) => s.reels.first.likeCount, 'count', 1),
      ],
    );

    // R4. The failure was written to `failure` while status stayed ready, so
    // nothing rendered it — the heart just rolled back with no explanation.
    blocTest<ReelsFeedBloc, ReelsFeedState>(
      'rolls back and surfaces a one-shot message when the like fails',
      setUp: () => when(() => repo.like('r1'))
          .thenAnswer((_) async => const Err(NetworkFailure())),
      build: build,
      seed: () => ReelsFeedState(
        status: FeedStatus.ready,
        reels: [_reel('r1')],
      ),
      act: (b) => b.add(const ReelLikeToggled('r1')),
      skip: 1,
      expect: () => [
        isA<ReelsFeedState>()
            .having((s) => s.reels.first.likedByMe, 'rolled back', false)
            .having((s) => s.reels.first.likeCount, 'count', 0)
            .having((s) => s.actionFailure, 'one-shot', isA<NetworkFailure>())
            .having((s) => s.status, 'feed still usable', FeedStatus.ready),
      ],
    );

    // R1. index was captured before the await; a refresh during the round trip
    // shortened the list and `[index] = reel` threw RangeError.
    blocTest<ReelsFeedBloc, ReelsFeedState>(
      'does not throw when the reel disappears during the round trip',
      setUp: () => when(() => repo.like('r3'))
          .thenAnswer((_) async => const Err(NetworkFailure())),
      build: build,
      seed: () => ReelsFeedState(
        status: FeedStatus.ready,
        reels: [_reel('r1'), _reel('r2'), _reel('r3')],
      ),
      act: (b) async {
        b.add(const ReelLikeToggled('r3'));
        await Future<void>.delayed(Duration.zero);
        // Simulates a refresh landing mid-flight.
        b.emit(
          ReelsFeedState(status: FeedStatus.ready, reels: [_reel('r9')]),
        );
      },
    );

    // R6. Two taps ran concurrently and their rollbacks restored stale
    // snapshots, drifting the count.
    blocTest<ReelsFeedBloc, ReelsFeedState>(
      'ignores a second tap while the first is in flight',
      setUp: () => when(() => repo.like('r1')).thenAnswer((_) async {
        // ئەم دواکەوتنە وادەکات لایکی یەکەم کاتی بوێت، بەمەش لایکی دووەم بلۆک دەبێت!
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Success(null);
      }),
      build: build,
      seed: () => ReelsFeedState(
        status: FeedStatus.ready,
        reels: [_reel('r1')],
      ),
      act: (b) => b
        ..add(const ReelLikeToggled('r1'))
        ..add(const ReelLikeToggled('r1')),
      expect: () => [
        isA<ReelsFeedState>()
            .having((s) => s.reels.first.likeCount, 'count', 1),
      ],
      verify: (_) => verify(() => repo.like('r1')).called(1),
    );
  });

  group('refresh', () {
    // R3. This emitted a const state whose reels list is empty, so the feed
    // visibly emptied — including the video being watched — before refilling.
    blocTest<ReelsFeedBloc, ReelsFeedState>(
      'keeps the current reels on screen while refetching',
      setUp: () => when(() => repo.fetchFeed(limit: any(named: 'limit')))
          .thenAnswer((_) async => throw UnimplementedError()),
      build: build,
      seed: () => ReelsFeedState(
        status: FeedStatus.ready,
        reels: [_reel('r1'), _reel('r2')],
        cursor: 'c1',
      ),
      act: (b) => b.add(const FeedRefreshed()),
      expect: () => [
        isA<ReelsFeedState>()
            .having((s) => s.status, 'status', FeedStatus.loading)
            .having((s) => s.reels.length, 'reels kept', 2)
            .having((s) => s.cursor, 'cursor reset', isNull)
            .having((s) => s.hasMore, 'hasMore reset', true),
      ],
      errors: () => <Matcher>[isA<UnimplementedError>()],
    );
  });
}
