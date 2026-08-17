import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Cold-start trace (§6).
///
/// §6 names cold start and video time-to-first-frame as the two paths worth
/// measuring. Time-to-first-frame is measured inside the controller pool; this is
/// the other one.
///
/// Measured from the earliest point Dart code runs to the first frame the user
/// could actually look at. That span is the one that decides whether the app
/// feels fast, and it is also the one that quietly grows: every dependency added
/// to `configureDependencies`, every `await` moved ahead of the first frame,
/// lands here. Without a number, that growth is invisible until someone
/// complains the app is slow to open.
///
/// Attributes rather than separate traces, so one dashboard row shows where the
/// time went instead of three unrelated ones.
class StartupTrace {
  StartupTrace._();

  static Trace? _trace;
  static DateTime? _startedAt;

  /// Called first thing in `bootstrap()`, before Firebase.initializeApp — the
  /// trace itself cannot start until Performance exists, so the wall clock is
  /// captured here and the trace is opened as soon as it can be.
  static void markProcessStart() {
    _startedAt ??= DateTime.now();
  }

  static Future<void> begin() async {
    if (kDebugMode) return; // debug timings are noise: no AOT, hot reload, etc.
    _trace = FirebasePerformance.instance.newTrace('cold_start');
    await _trace?.start();
  }

  /// Records how long one phase of startup took.
  static void mark(String phase) {
    final started = _startedAt;
    if (started == null) return;
    _trace?.setMetric(
      phase,
      DateTime.now().difference(started).inMilliseconds,
    );
  }

  /// Called from the first frame callback, not from the end of `main` — `main`
  /// returning means the widget tree was described, not that anything was
  /// painted, and the gap between those two is exactly what a slow first build
  /// hides in.
  static Future<void> completeOnFirstFrame() async {
    final started = _startedAt;
    if (started == null || _trace == null) return;

    _trace!.setMetric(
      'total_ms',
      DateTime.now().difference(started).inMilliseconds,
    );
    await _trace!.stop();
    _trace = null;
  }
}
