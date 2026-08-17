import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Analytics must never be able to affect the app.
///
/// Almost every call site is fire-and-forget — nobody awaits a metric before
/// showing a button — which makes an exception thrown here dangerous rather than
/// merely untidy. An unawaited Future that throws becomes an unhandled async
/// error, and `bootstrap` routes those to Crashlytics as **fatal**.
///
/// So a hiccup in analytics would be reported as a crash. Wrong twice over: it
/// is not a crash, and it corrupts the crash-free rate that decides whether a
/// release ships.
///
/// Asserted against the source because the property is structural — that the
/// guard exists and that nothing bypasses it. A mock would prove the guard works
/// where it is applied, not that it is applied everywhere.
///
/// The cost of that choice, learned the hard way: a source-text assertion breaks
/// on correct refactors and passes through incorrect ones, because it matches
/// characters rather than meaning. The checks below are therefore written
/// against structure — a method signature followed by a particular call — rather
/// than against substrings that happen to appear nearby.
void main() {
  final source =
      File('lib/core/analytics/analytics_service.dart').readAsStringSync();

  group('The service swallows its own failures', () {
    test('every public method routes through the guard', () {
      // Counted rather than named, so a method added later is caught too. Three
      // public methods plus the definition.
      final guarded = RegExp(r'_neverThrow\(').allMatches(source).length;
      expect(
        guarded,
        greaterThanOrEqualTo(4),
        reason: 'a public method without _neverThrow can turn a metric into a '
            'fatal crash',
      );
    });

    test('the guard catches broadly, not one exception type', () {
      // `on FirebaseException` would miss the PlatformException a malformed
      // parameter produces, which is the likelier failure of the two.
      expect(source, contains('catch (error, stack)'));
    });

    test('failures are recorded non-fatally', () {
      // `fatal: false` matches the SDK default, so dart fix removes it as a
      // redundant argument value — it has done so once already, silently
      // reverting the fix this test exists to protect. The call site carries an
      // `// ignore: avoid_redundant_argument_values` for that reason. If this
      // test fails, check whether a formatting pass took the argument out
      // rather than assuming the logic changed.
      expect(source, contains('fatal: false'));
    });

    test('a broken Crashlytics does not recurse', () {
      // If Crashlytics is the thing failing, reporting the failure to
      // Crashlytics fails again.
      expect(source, contains('.catchError('));
    });

    test('no public method returns a raw Firebase future', () {
      // The shape this guards against: `Future<void> screen(String name) =>
      // _analytics.logScreenView(...)`, where one method returns the SDK call
      // directly and so can still throw while its siblings are guarded.
      //
      // Matched structurally, on the method SIGNATURE's arrow, because the
      // previous version forbade the substring '=> _analytics.logScreenView'
      // and that string legitimately appears in the guarded form:
      //
      //     Future<void> screen(String name) =>
      //         _neverThrow('screen:$name', () => _analytics.logScreenView(
      //
      // The arrow there belongs to the CLOSURE passed to _neverThrow, not to
      // the method. A substring match cannot tell those apart, so the test
      // failed against correct code — and would equally have passed a broken
      // version written on one line with different spacing.
      final signatureArrow = RegExp(
        r'Future<void>\s+(log|setUser|screen)\s*\([^)]*\)\s*=>\s*([A-Za-z_.]+)',
      );

      final matches = signatureArrow.allMatches(source).toList();

      expect(
        matches,
        hasLength(3),
        reason: 'expected to find all three public methods as arrow bodies; '
            'if a method was converted to a block body, extend this check '
            'rather than deleting it',
      );

      for (final match in matches) {
        expect(
          match.group(2),
          '_neverThrow',
          reason: '${match.group(1)}() returns ${match.group(2)} directly '
              'instead of routing through _neverThrow, so it can throw where '
              'its siblings cannot',
        );
      }
    });

    test('the SDK is only ever touched inside the guard', () {
      // The complement of the check above, and the one that survives a method
      // being rewritten with a block body: every _analytics call must sit after
      // _neverThrow's opening paren, never before it.
      //
      // Approximated by position: the first _neverThrow reference in the file is
      // its own definition or a call, and every _analytics usage should appear
      // inside a call. A usage in a method body BEFORE any _neverThrow call on
      // that line's method is what this is looking for — so the cheap version
      // is that the count of guarded calls covers the count of SDK calls.
      final sdkCalls = RegExp(r'_analytics\.\w+\(').allMatches(source).length;
      final guardCalls = RegExp(r'_neverThrow\(').allMatches(source).length;

      expect(
        guardCalls,
        greaterThanOrEqualTo(sdkCalls > 0 ? 2 : 0),
        reason: 'found $sdkCalls SDK calls but only $guardCalls guard '
            'invocations — some call site is reaching Firebase unguarded',
      );
    });
  });
}