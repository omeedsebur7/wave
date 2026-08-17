import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the chain that lets anyone place an order at all.
///
/// `phone_verified` is the flag `placeOrder` requires, Security Rules forbid
/// the client from writing it, and `onPhoneLinked` is the only thing that can
/// set it. If any link in that chain breaks, the checkout gate closes
/// permanently and **no user can ever complete a purchase** — while every
/// individual piece still looks correctly built.
///
/// This is a source-level test on purpose. The failure it guards against is
/// not a logic error inside one file; it is three files each being reasonable
/// and collectively wrong. Nothing that mocks a repository would catch it.
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('The checkout identity gate is reachable end to end', () {
    test('placeOrder requires phone_verified', () {
      expect(
        read('functions/src/orders/placeOrder.ts'),
        contains('phone_verified'),
        reason: 'the gate itself has gone missing',
      );
    });

    test('Security Rules forbid the client writing phone_verified', () {
      expect(
        read('firestore.rules'),
        contains("unchanged('phone_verified')"),
        reason: 'a client that can set this bypasses the gate entirely',
      );
    });

    test('a Cloud Function exists that can set it', () {
      final fn = read('functions/src/common/onPhoneLinked.ts');
      expect(fn, contains('phone_verified: true'));
      expect(
        fn,
        contains('.getUser('),
        reason: 'it must re-read the auth record rather than trust the request',
      );
    });

    test('that function is exported, or it is not deployed', () {
      expect(read('functions/src/index.ts'), contains('onPhoneLinked'));
    });

    test('the client actually calls it', () {
      // The bug this test exists for: `onPhoneLinked` is a callable, not a
      // background trigger. `linkWithCredential` writes nothing to Firestore,
      // so there is nothing for a trigger to fire on — it must be invoked.
      expect(
        read('lib/features/auth/data/repositories/auth_repository_impl.dart'),
        contains("httpsCallable('onPhoneLinked')"),
        reason: 'without this call phone_verified is never set and the '
            'checkout gate is permanently closed',
      );
    });

    test('both OTP paths confirm verification', () {
      // Linking a phone to an existing account, and signing in with a phone,
      // both verify the number. Covering only one leaves half of users stuck
      // at a gate asking them to verify the number they just used.
      final src =
          read('lib/features/auth/data/repositories/auth_repository_impl.dart');
      final confirmCalls =
          RegExp(r'_confirmPhoneVerified\(\)').allMatches(src).length;
      expect(
        confirmCalls,
        greaterThanOrEqualTo(3),
        reason: 'expected the helper plus a call from each OTP path',
      );
    });

    test('the client reads the same field the function writes', () {
      expect(
        read('lib/features/checkout/data/repositories/checkout_repository_impl.dart'),
        contains("data['phone_verified']"),
      );
    });
  });
}
