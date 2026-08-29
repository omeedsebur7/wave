import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wave/core/services/bunny_stream_service.dart';
import 'package:wave/features/reels/presentation/widgets/reel_controller_pool.dart';

class _MockBunny extends Mock implements BunnyStreamService {}

/// Records what actually happened to each player, so the tests can assert on
/// `dispose()` specifically — not on `pause()`, which is the mistake this whole
/// class exists to prevent.
class _FakePlayer implements PooledPlayer {
  _FakePlayer(this.url);

  final String url;

  static final created = <_FakePlayer>[];
  static final disposed = <_FakePlayer>[];

  bool _initialized = false;
  bool playing = false;
  bool isDisposed = false;

  /// Set to simulate a slow URL sign or a slow decoder handshake.
  static Duration initDelay = Duration.zero;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    if (initDelay > Duration.zero) await Future<void>.delayed(initDelay);
    _initialized = true;
  }

  // Named, not positional — matches PooledPlayer.setLooping's signature in
  // reel_controller_pool.dart, which moved to a named `looping` parameter
  // (avoid_positional_boolean_parameters: PooledPlayer is our own interface,
  // unlike VideoPlayerController.setLooping, so there was no external
  // contract stopping the fix). This override has to match exactly or the
  // analyzer reports invalid_override, which is what sent this file back
  // for a one-line change.
  @override
  Future<void> setLooping({required bool looping}) async {}

  @override
  Future<void> play() async => playing = true;

  @override
  Future<void> pause() async => playing = false;

  @override
  Future<void> dispose() async {
    isDisposed = true;
    disposed.add(this);
  }

  static void reset() {
    created.clear();
    disposed.clear();
    initDelay = Duration.zero;
  }
}

List<({String reelId, String bunnyVideoId})> _feed(int count) => [
      for (var i = 0; i < count; i++)
        (reelId: 'reel_$i', bunnyVideoId: 'video_$i'),
    ];

void main() {
  late _MockBunny bunny;
  late ReelControllerPool pool;

  setUp(() {
    _FakePlayer.reset();
    bunny = _MockBunny();

    // BOTH calls in _create must be stubbed.
    //
    // maxHeightForCurrentNetwork had no stub at all, so mocktail threw
    // MissingStubError on the first line of the try block — and _create's
    // `catch (_)` swallowed it. Every player creation failed silently, so
    // _FakePlayer.created stayed empty and every leak assertion in this file
    // passed against nothing.
    when(() => bunny.maxHeightForCurrentNetwork()).thenAnswer((_) async => 720);

    // The named argument matters too: `playbackUrl(any())` registers only the
    // one-positional-argument form, and the real call passes maxHeight:. A
    // stub that does not match is the same as no stub.
    when(
      () => bunny.playbackUrl(any(), maxHeight: any(named: 'maxHeight')),
    ).thenAnswer(
      (i) async => 'https://cdn.test/${i.positionalArguments[0]}.m3u8',
    );

    pool = ReelControllerPool(
      bunny,
      playerFactory: (url) {
        final player = _FakePlayer(url);
        _FakePlayer.created.add(player);
        return player;
      },
    );
  });

  tearDown(() => pool.disposeAll());

  /// Page, settle, and PROVE a player was built.
  ///
  /// Almost every assertion in this file is of the form "nothing leaked" —
  /// isEmpty, count <= max, count == 0. All of those hold trivially when no
  /// player was ever created, which is precisely the state a broken stub put
  /// this suite in. This helper makes the precondition explicit so a harness
  /// failure can never again read as a clean pass.
  Future<void> pageTo(
    int index,
    List<({String reelId, String bunnyVideoId})> reels, {
    Duration settle = Duration.zero,
  }) async {
    await pool.onPageChanged(index: index, reels: reels);
    await Future<void>.delayed(settle);
    expect(
      _FakePlayer.created,
      isNotEmpty,
      reason: 'no player was created — check the BunnyStreamService stubs '
          'before reading anything below as a pass',
    );
  }

  group('The window invariant — the OOM guard', () {
    test(
      'scrolling a 50-Reel feed never holds more than maxControllers',
      () async {
        final reels = _feed(50);

        for (var i = 0; i < reels.length; i++) {
          await pageTo(i, reels);

          expect(
            pool.activeControllerCount,
            lessThanOrEqualTo(ReelControllerPool.maxControllers),
            reason: 'exceeded the window at index $i — this is the exact '
                'condition that produces a native OOM crash forty Reels into '
                'a session, with no Dart stack trace',
          );
        }

        // The window must actually be full, not merely under the cap.
        expect(pool.activeControllerCount, greaterThan(0));
      },
    );

    test('players leaving the window are DISPOSED, not merely paused', () async {
      final reels = _feed(10);

      await pageTo(0, reels);
      await pageTo(5, reels);

      // A paused player still holds its native decoder. Pausing instead of
      // disposing is the bug, and it is invisible without this assertion.
      final orphans = _FakePlayer.created
          .where((p) => !p.isDisposed && p.url.contains('video_0'));

      expect(
        orphans,
        isEmpty,
        reason: 'reel_0 left the window and must have been disposed',
      );
      expect(_FakePlayer.disposed, isNotEmpty);
    });

    test('the visible Reel plays on the first page change', () async {
      final reels = _feed(10);

      // ONE page change, not two.
      //
      // This previously called onPageChanged(3) twice and asserted
      // `playing.length <= 1` with the url check inside `if (playing.isNotEmpty)`
      // — so zero playing satisfied it. Both details mattered: the second call
      // is what actually started playback, because on the first landing the
      // players do not exist yet when _applyPlaybackState runs. In production
      // onPageChanged fires once per swipe, so the test was passing a scenario
      // the app never performs.
      await pageTo(3, reels);

      final playing = _FakePlayer.created.where((p) => p.playing).toList();
      expect(
        playing,
        hasLength(1),
        reason: 'landing on a Reel must start it playing, not leave a frozen '
            'first frame',
      );
      expect(playing.single.url, contains('video_3'));
    });

    test('neighbours are buffered but silent', () async {
      final reels = _feed(10);
      await pageTo(3, reels);

      final neighbours = _FakePlayer.created.where(
        (p) => !p.isDisposed && !p.url.contains('video_3'),
      );
      expect(neighbours, isNotEmpty, reason: 'preloading is the point');
      expect(neighbours.every((p) => !p.playing), isTrue);
    });

    test('the window tracks the current index', () async {
      final reels = _feed(10);

      await pool.onPageChanged(index: 4, reels: reels);
      expect(pool.wantedIds, {'reel_3', 'reel_4', 'reel_5'});

      await pool.onPageChanged(index: 0, reels: reels);
      // No reel_-1 — the window clamps at the ends rather than wrapping.
      expect(pool.wantedIds, {'reel_0', 'reel_1'});
    });
  });

  group('Races that leak', () {
    test(
      'a player finishing initialisation after its Reel left the window is '
      'disposed rather than adopted',
      () async {
        // The fast-scroller case. Without the post-await window re-check, every
        // quick swipe leaves an orphaned native decoder behind.
        _FakePlayer.initDelay = const Duration(milliseconds: 50);
        final reels = _feed(20);

        await pool.onPageChanged(index: 0, reels: reels);
        await pool.onPageChanged(index: 10, reels: reels);
        await Future<void>.delayed(const Duration(milliseconds: 120));

        expect(
          _FakePlayer.created,
          isNotEmpty,
          reason: 'nothing was built, so nothing could have leaked',
        );
        expect(
          pool.activeControllerCount,
          lessThanOrEqualTo(ReelControllerPool.maxControllers),
        );

        final leaked = _FakePlayer.created.where(
          (p) => !p.isDisposed && !p.url.contains(RegExp('video_(9|10|11)')),
        );
        expect(leaked, isEmpty, reason: 'orphaned players from the fast scroll');

        // The abandoned Reels must never have had a player CONSTRUCTED at all.
        //
        // This previously asserted `_FakePlayer.disposed, isNotEmpty` — that
        // index 0 and 1 were built and then released. That was wrong about the
        // pool, and the pool is better than the assertion demanded: the window
        // re-check in _create lands BEFORE _playerFactory —
        //
        //     if (_disposed || !_wanted.contains(reelId)) return null;
        //     player = _playerFactory(url);
        //
        // so a Reel that left the window while its URL was being signed never
        // costs a native decoder in the first place. Never allocating beats
        // allocating and freeing, and a test that insisted on `disposed` being
        // non-empty was locking in the weaker behaviour — it would have started
        // passing if someone moved the re-check after construction, which is
        // the regression this file exists to catch.
        final abandoned = _FakePlayer.created.where(
          (p) =>
              p.url.endsWith('/video_0.m3u8') ||
              p.url.endsWith('/video_1.m3u8'),
        );
        expect(
          abandoned,
          isEmpty,
          reason: 'index 0 and 1 left the window during URL signing, so no '
              'player should have been constructed for them',
        );

        // And the window it DID land on is genuinely populated, so the two
        // assertions above are not both satisfied by an idle pool.
        expect(
          _FakePlayer.created.where((p) => !p.isDisposed),
          isNotEmpty,
          reason: 'the destination window must hold live players',
        );
      },
    );

    test('two rapid page changes to the same Reel create one player', () async {
      final reels = _feed(10);

      await Future.wait([
        pool.onPageChanged(index: 2, reels: reels),
        pool.onPageChanged(index: 2, reels: reels),
      ]);
      await Future<void>.delayed(Duration.zero);

      final forReel2 =
          _FakePlayer.created.where((p) => p.url.contains('video_2')).length;
      expect(forReel2, 1);
    });

    test('a failed URL sign leaves nothing behind', () async {
      // Overrides the working stub from setUp. Before that stub existed this
      // test passed for the wrong reason: the call was already throwing, so it
      // proved nothing about the failure path.
      when(() => bunny.playbackUrl(any(), maxHeight: any(named: 'maxHeight')))
          .thenThrow(Exception('offline'));

      await pool.onPageChanged(index: 0, reels: _feed(5));
      await Future<void>.delayed(Duration.zero);

      expect(pool.activeControllerCount, 0);
      expect(_FakePlayer.created, isEmpty);
    });

    test('a failed decoder handshake releases the player it built', () async {
      // The other half of the catch block: the URL signs fine, the player is
      // constructed, and initialize() throws. `player?.dispose()` in the catch
      // is the only thing standing between that and a leaked native decoder,
      // and nothing exercised it.
      pool = ReelControllerPool(
        bunny,
        playerFactory: (url) {
          final player = _ThrowingPlayer(url);
          _FakePlayer.created.add(player);
          return player;
        },
      );

      await pool.onPageChanged(index: 0, reels: _feed(5));
      await Future<void>.delayed(Duration.zero);

      expect(_FakePlayer.created, isNotEmpty);
      expect(pool.activeControllerCount, 0);
      expect(
        _FakePlayer.created.every((p) => p.isDisposed),
        isTrue,
        reason: 'a player built before initialize() threw still holds a '
            'decoder and must be disposed',
      );
    });
  });

  group('Teardown', () {
    test('disposeAll releases every player', () async {
      final reels = _feed(10);
      await pageTo(5, reels);

      expect(pool.activeControllerCount, greaterThan(0));

      await pool.disposeAll();

      expect(pool.activeControllerCount, 0);
      expect(
        _FakePlayer.created.every((p) => p.isDisposed),
        isTrue,
        reason: 'nothing may survive the feed',
      );
    });

    test('a page change after disposal is a no-op, not a resurrection', () async {
      await pool.disposeAll();
      await pool.onPageChanged(index: 0, reels: _feed(5));
      await Future<void>.delayed(Duration.zero);

      expect(pool.activeControllerCount, 0);
      expect(_FakePlayer.created, isEmpty);
    });

    test('an out-of-range index is ignored rather than throwing', () async {
      await pool.onPageChanged(index: 99, reels: _feed(5));
      expect(pool.activeControllerCount, 0);
    });

    test('an empty feed does not throw', () async {
      await pool.onPageChanged(index: 0, reels: const []);
      expect(pool.activeControllerCount, 0);
    });
  });

  group('Lifecycle', () {
    test('pauseAll stops everything, for backgrounding', () async {
      // Otherwise a Reel keeps talking from the user's pocket.
      final reels = _feed(10);
      await pageTo(3, reels);

      // Proves something was playing first — `every((p) => !p.playing)` is
      // trivially true over players that never started.
      expect(_FakePlayer.created.any((p) => p.playing), isTrue);

      await pool.pauseAll();

      expect(_FakePlayer.created.every((p) => !p.playing), isTrue);
    });
  });
}

/// Fails at the decoder handshake, after construction.
class _ThrowingPlayer extends _FakePlayer {
  _ThrowingPlayer(super.url);

  @override
  Future<void> initialize() async => throw Exception('decoder unavailable');
}
