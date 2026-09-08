import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';


/// Thin wrapper so features depend on an interface, not on Firebase directly —
/// and so every event also lands as a Crashlytics breadcrumb, which is what
/// makes a crash report readable after the fact.
abstract class AnalyticsService {
  Future<void> log(String name, {Map<String, Object>? params});
  Future<void> setUser(String? uid);
  Future<void> screen(String name);
}


class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics, this._crashlytics);

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> log(String name, {Map<String, Object>? params}) =>
      _neverThrow('log:$name', () async {
        await _analytics.logEvent(name: name, parameters: params);
        await _crashlytics.log('$name ${params ?? ''}');
      });

  @override
  Future<void> setUser(String? uid) => _neverThrow('setUser', () async {
        await _analytics.setUserId(id: uid);
        await _crashlytics.setUserIdentifier(uid ?? '');
      });

  @override
  Future<void> screen(String name) => _neverThrow(
        'screen:$name',
        () => _analytics.logScreenView(screenName: name),
      );

  /// Runs [action] and discards any failure.
  ///
  /// Analytics calls are deliberately fire-and-forget at most call sites —
  /// nobody should await a metric before showing a button. That makes an
  /// exception here genuinely dangerous rather than merely untidy: an unawaited
  /// Future that throws becomes an unhandled async error, and `bootstrap` routes
  /// those to Crashlytics as **fatal**.
  ///
  /// So a hiccup in analytics — an uninitialised Firebase in a widget test, a
  /// dropped connection, a malformed parameter the SDK rejects — would be
  /// reported as a crash. That is wrong twice over: it is not a crash, and it
  /// corrupts the crash-free rate that decides whether a release ships.
  ///
  /// Swallowing here rather than at each call site because there are a dozen of
  /// them and the next one added would forget. Measurement must never be able to
  /// affect the thing it measures.
  ///
  /// A NOTE ON `fatal: false` BELOW, because it has been silently stripped by
  /// `dart fix --apply` four times across this file's history:
  ///
  /// The argument is explicit on purpose, not merely the SDK's current default.
  /// An analytics failure reported as fatal corrupts the crash-free rate that
  /// decides whether a release ships — see
  /// test/core/analytics_isolation_test.dart, which asserts the literal string
  /// 'fatal: false' is present in this file.
  ///
  /// The first attempt to protect it put the `// ignore:` comment several lines
  /// above the argument, separated by other comment lines. That does not work:
  /// an `ignore:` comment suppresses the diagnostic on the NEXT LINE ONLY, and
  /// the next line was another comment, not the `fatal: false,` argument — so
  /// the diagnostic on the real line was never suppressed and `dart fix`
  /// removed it a fourth time. The ignore comment below is INLINE, on the same
  /// line as the argument it protects, which is the only placement `dart fix`
  /// actually respects here.
  Future<void> _neverThrow(
    String context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error, stack) {
      // Reported non-fatally so the failure is still visible. An analytics
      // pipeline that has quietly stopped working is worth knowing about; it
      // just is not worth a crash report.
      if (kDebugMode) {
        debugPrint('Analytics failed ($context): $error');
      }
      await _crashlytics
          .recordError(
            error,
            stack,
            reason: 'analytics: $context',
            fatal: false, // ignore: avoid_redundant_argument_values
          )
          .catchError((_) {});
    }
  }
}
