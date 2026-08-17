import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/error/failures.dart';

void main() {
  group('Failure translation (§9)', () {
    late Map<String, Map<String, dynamic>> arbs;
    late String mapper;

    setUpAll(() {
      arbs = {
        for (final locale in ['en', 'ckb', 'ar'])
          locale: json.decode(
            File('lib/l10n/app_$locale.arb').readAsStringSync(),
          ) as Map<String, dynamic>,
      };
      mapper = File('lib/core/error/failure_text.dart').readAsStringSync();
    });

    test('every reason has an arm in failureText', () {
      // `failureText` switches on FailureReason with no default arm, so a
      // missing reason is a compile error rather than a runtime surprise. This
      // test exists for the case the compiler cannot see: someone silencing the
      // error by adding `_ => something` instead of translating the reason.
      expect(
        mapper.contains('_ =>'),
        isFalse,
        reason: 'failureText has grown a default arm. A catch-all makes new '
            'reasons compile without a translation, which is how an English '
            'sentence reaches an Arabic screen.',
      );

      for (final reason in FailureReason.values) {
        expect(
          mapper.contains('FailureReason.${reason.name} =>'),
          isTrue,
          reason: '${reason.name} has no arm in failureText',
        );
      }
    });

    test('every key failureText reaches exists in all three locales', () {
      final used = RegExp(r'l10n\.(\w+)')
          .allMatches(mapper)
          .map((m) => m.group(1)!)
          .toSet();

      expect(used, isNotEmpty);

      for (final key in used) {
        for (final locale in arbs.keys) {
          expect(
            arbs[locale]![key],
            isNotNull,
            reason: '$key is referenced by failureText but missing from '
                'app_$locale.arb — that locale would fall back to English',
          );
        }
      }
    });

    test('a reason is never mapped twice', () {
      // Two arms for one reason means one of them is unreachable, and which one
      // depends on ordering — so the translation that actually shows is decided
      // by accident.
      for (final reason in FailureReason.values) {
        // String implements Pattern, so allMatches is already available —
        // no helper needed.
        final arms =
            'FailureReason.${reason.name} =>'.allMatches(mapper).length;
        expect(arms, lessThanOrEqualTo(1), reason: reason.name);
      }
    });

    test('unknown is the default reason', () {
      // Every Failure constructed without a reason has to land on something
      // translatable. `unknown` renders a deliberate generic message; a null
      // reason would render nothing at all.
      const failure = ServerFailure('boom');
      expect(failure.reason, FailureReason.unknown);
    });

    test('message stays developer-facing and is not the rendered text', () {
      // The whole point of the reason channel: a failure can carry an English
      // diagnostic for Crashlytics without that string being what the user
      // reads.
      const failure = AuthFailure(
        'FirebaseAuth: internal-error',
        reason: FailureReason.signInFailed,
      );
      expect(failure.message, contains('internal-error'));
      expect(failure.reason, FailureReason.signInFailed);
    });
  });
}

