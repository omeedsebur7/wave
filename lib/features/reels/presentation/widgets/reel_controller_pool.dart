import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:wave/core/services/bunny_stream_service.dart';

/// The minimum a pooled player must expose.
///
/// This interface exists so the pool can be tested. `VideoPlayerController`
/// needs a live platform channel, which means the real thing cannot be
/// constructed in a unit test — and the invariant this class enforces is the
/// one bug in the app that absolutely must be covered by a test rather than
/// discovered in Crashlytics.
abstract class PooledPlayer {
  bool get isInitialized;
  Future<void> initialize();
  Future<void> setLooping(bool looping);
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

/// Production adapter over the real controller.
class VideoPlayerPooledPlayer implements PooledPlayer {
  VideoPlayerPooledPlayer(this.controller);

  final VideoPlayerController controller;

  @override
  bool get isInitialized => controller.value.isInitialized;

  @override
  Future<void> initialize() => controller.initialize();

  @override
  Future<void> setLooping(bool looping) => controller.setLooping(looping);

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> dispose() => controller.dispose();
}

typedef PlayerFactory = PooledPlayer Function(String url);

/// Bounded video-controller window (§6).
///
/// THIS IS A HARD ARCHITECTURAL RULE, not an optimisation to add later if crash
/// reports show up. Every player holds a native ExoPlayer/AVPlayer instance with
/// its own decoder and buffer. Flutter's garbage collector does not free those —
/// only an explicit `dispose()` does. Keeping players for every Reel a user
/// scrolls past is the single most common cause of native-memory OOM crashes in
/// Flutter video feeds, and it presents as a random crash forty Reels into a
/// session with no Dart stack trace, which is close to impossible to diagnose
/// after the fact.
///
/// So: at most three players exist at any moment — previous (kept briefly for
/// back-scroll), current, next (preloaded so the swipe is instant). Anything
/// outside that window is disposed, not paused.
class ReelControllerPool {
  ReelControllerPool(
    this._bunny, {
    PlayerFactory? playerFactory,
    this.onFirstFrame,
  }) : _playerFactory = playerFactory ??
            ((url) => VideoPlayerPooledPlayer(
                  VideoPlayerController.networkUrl(Uri.parse(url)),
                ));

  final BunnyStreamService _bunny;
  final PlayerFactory _playerFactory;

  /// Reports how long a Reel took from requested to playable (§6).
  ///
  /// Measured here because this is the only place that sees the whole span —
  /// signing the URL, opening the stream, and the decoder handshake. Measuring
  /// it in the widget would miss everything before the controller exists,
  /// which on a poor connection is most of the wait.
  final void Function(Duration)? onFirstFrame;

  /// current - 1, current, current + 1. Widening this is exactly the change
  /// that reintroduces the crash — don't, without a memory profile to justify.
  static const windowRadius = 1;

  /// The invariant the tests assert against.
  static const maxControllers = windowRadius * 2 + 1;

  final _players = HashMap<String, PooledPlayer>();
  final _initialising = HashMap<String, Future<PooledPlayer?>>();

  /// The Reel ids currently inside the window. Maintained by [onPageChanged]
  /// and consulted by [_create], because signing a Bunny URL takes a network
  /// round-trip and a fast scroller can leave the window before it returns.
  final _wanted = <String>{};

  int _currentIndex = 0;

  /// Which Reel is actually on screen.
  ///
  /// Tracked as an id, not just [_currentIndex], because [_create] finishes
  /// long after [onPageChanged] returns and has no access to the reel list. It
  /// is the difference between "inside the window" and "the one being watched",
  /// and conflating the two is what left the visible Reel paused.
  String? _currentReelId;

  bool _disposed = false;

  PooledPlayer? playerFor(String reelId) => _players[reelId];

  bool isReady(String reelId) => _players[reelId]?.isInitialized ?? false;

  /// Call on every page change. Disposes everything outside the window, then
  /// preloads inside it — in that order, so decoders are freed before new ones
  /// are allocated. That matters on devices with a hard cap on concurrent
  /// hardware decoders.
  Future<void> onPageChanged({
    required int index,
    required List<({String reelId, String bunnyVideoId})> reels,
  }) async {
    if (_disposed || reels.isEmpty) return;
    if (index < 0 || index >= reels.length) return;

    _currentIndex = index;
    _currentReelId = reels[index].reelId;

    final keep = <String>{};
    for (var i = index - windowRadius; i <= index + windowRadius; i++) {
      if (i >= 0 && i < reels.length) keep.add(reels[i].reelId);
    }

    // Update before any await, so an initialisation that finishes later checks
    // against the CURRENT window rather than the one that started it.
    _wanted
      ..clear()
      ..addAll(keep);

    for (final id in _players.keys.where((id) => !keep.contains(id)).toList()) {
      await _disposeOne(id);
    }

    // Current first so playback starts immediately, then the neighbours.
    final ordered = <({String reelId, String bunnyVideoId})>[
      reels[index],
      for (var i = index + 1; i <= index + windowRadius && i < reels.length; i++)
        reels[i],
      for (var i = index - windowRadius; i < index; i++)
        if (i >= 0) reels[i],
    ];

    for (final r in ordered) {
      unawaited(_ensure(r.reelId, r.bunnyVideoId));
    }

    // Only affects players that ALREADY exist — a back-scroll into a Reel still
    // in the window. On a first landing this runs while creation is in flight
    // and _players is empty, which is why _create has to settle its own
    // playback state rather than relying on this.
    await _applyPlaybackState(reels[index].reelId);
  }

  /// Only the visible Reel plays. Neighbours stay buffered and paused.
  Future<void> _applyPlaybackState(String currentReelId) async {
    for (final entry in _players.entries) {
      if (!entry.value.isInitialized) continue;
      if (entry.key == currentReelId) {
        await entry.value.play();
      } else {
        await entry.value.pause();
      }
    }
  }

  Future<PooledPlayer?> _ensure(String reelId, String videoId) {
    final existing = _players[reelId];
    if (existing != null) return Future.value(existing);

    // Guard against a fast scroller triggering two inits for the same Reel.
    final inFlight = _initialising[reelId];
    if (inFlight != null) return inFlight;

    final future = _create(reelId, videoId);
    _initialising[reelId] = future;
    return future;
  }

  Future<PooledPlayer?> _create(String reelId, String videoId) async {
    final started = DateTime.now();
    PooledPlayer? player;
    try {
      // Signed, short-lived HLS URL — the signing key never touches the device.
      //
      // The resolution cap is applied here rather than at the widget: it has to
      // be decided before the player opens the stream, because a player already
      // negotiating an adaptive ladder will not renegotiate downward on its own.
      final maxHeight = await _bunny.maxHeightForCurrentNetwork();
      final url = await _bunny.playbackUrl(videoId, maxHeight: maxHeight);

      // Re-check after the round-trip: the user may have scrolled past while
      // the URL was being signed, and constructing a player for a Reel nobody
      // is looking at is exactly the leak this class prevents.
      if (_disposed || !_wanted.contains(reelId)) return null;

      player = _playerFactory(url);
      await player.initialize();
      await player.setLooping(true);

      // And once more, because initialize() is itself a long await.
      if (_disposed || !_wanted.contains(reelId)) {
        await player.dispose();
        return null;
      }

      _players[reelId] = player;
      onFirstFrame?.call(DateTime.now().difference(started));

      // A player that finished initialising after the page settled still needs
      // to be told whether it is the visible one — which means comparing
      // against _currentReelId, not merely confirming it is somewhere in the
      // window. This previously paused unconditionally, so the Reel the user
      // had just swiped to sat on a frozen first frame: _applyPlaybackState had
      // already run and found nothing, and this ran afterwards and silenced the
      // one player that should have been playing.
      if (reelId == _currentReelId) {
        await player.play();
      } else {
        await player.pause();
      }

      return player;
    } catch (_) {
      // A player that got as far as being constructed must be released even if
      // initialize() threw, or a failed load leaks a native decoder.
      await player?.dispose();
      return null;
    } finally {
      _initialising.remove(reelId);
    }
  }

  Future<void> _disposeOne(String reelId) async {
    final player = _players.remove(reelId);
    if (player == null) return;
    if (player.isInitialized) await player.pause();
    // dispose(), not pause(). A paused player still holds its native decoder.
    await player.dispose();
  }

  Future<void> pauseAll() async {
    for (final player in _players.values) {
      if (player.isInitialized) await player.pause();
    }
  }

  Future<void> resumeCurrent(String reelId) async {
    final player = _players[reelId];
    if (player != null && player.isInitialized) await player.play();
  }

  /// Called from the page's dispose. Nothing may survive the feed.
  ///
  /// Sets [_disposed] first so any initialisation still in flight releases its
  /// player instead of adopting it into a pool nobody will ever drain.
  Future<void> disposeAll() async {
    _disposed = true;
    _wanted.clear();
    _currentReelId = null;

    for (final id in _players.keys.toList()) {
      await _disposeOne(id);
    }
    _initialising.clear();
  }

  @visibleForTesting
  int get activeControllerCount => _players.length;

  @visibleForTesting
  int get currentIndex => _currentIndex;

  @visibleForTesting
  Set<String> get wantedIds => Set.unmodifiable(_wanted);
}
