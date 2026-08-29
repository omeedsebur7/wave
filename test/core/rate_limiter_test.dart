import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/utils/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    test('allows up to the cap, then throttles', () {
      final limiter =
          RateLimiter(maxEvents: 3, window: const Duration(minutes: 15));
      final t0 = DateTime(2026, 8, 4, 12);

      expect(limiter.check('+9647700000000', now: t0), isNull);
      expect(limiter.check('+9647700000000', now: t0), isNull);
      expect(limiter.check('+9647700000000', now: t0), isNull);
      expect(limiter.check('+9647700000000', now: t0), isNotNull);
    });

    test('buckets are independent — one number cannot throttle another', () {
      final limiter =
          RateLimiter(maxEvents: 1, window: const Duration(minutes: 15));
      final t0 = DateTime(2026, 8, 4, 12);

      expect(limiter.check('a', now: t0), isNull);
      expect(limiter.check('a', now: t0), isNotNull);
      expect(limiter.check('b', now: t0), isNull);
    });

    test('the window slides — old events expire', () {
      final limiter =
          RateLimiter(maxEvents: 2, window: const Duration(minutes: 15));
      final t0 = DateTime(2026, 8, 4, 12);

      // Cascaded: two consecutive calls on `limiter`, both discarding
      // check()'s return value — the two calls only exist to fill the
      // window before the assertions below inspect it. That repetition is
      // what cascade_invocations flags.
      limiter
        ..check('x', now: t0)
        ..check('x', now: t0);
      expect(limiter.check('x', now: t0), isNotNull);
      expect(
        limiter.check('x', now: t0.add(const Duration(minutes: 16))),
        isNull,
      );
    });
  });
}
