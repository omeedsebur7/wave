import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/seed.dart';
import 'helpers/test_bootstrap.dart';

/// Security abuse test, round 5: PAYMENT-GATE TYPE CONFUSION.
///
/// placeOrder.ts's own checks, seen in full earlier this session:
///
///   if (typeof paymentMethodId !== "string" || paymentMethodId.trim()
///       .length === 0) {
///     throw new HttpsError("invalid-argument", ...);
///   }
///   ...
///   const PHASE_1_ALLOWED_PAYMENT_METHODS = new Set(["cash_on_delivery"]);
///   if (!PHASE_1_ALLOWED_PAYMENT_METHODS.has(cleanPaymentMethodId)) {
///     throw new HttpsError("failed-precondition", ...);
///   }
///
/// Two checks, two different failure codes, and that distinction is what
/// these tests actually verify: `invalid-argument` means the TYPE was wrong
/// before any business logic ran; `failed-precondition` means the type was
/// fine but the VALUE is not allowed yet. Getting these swapped, or getting
/// neither and instead throwing `internal`, would mean a malformed request
/// is reaching code that assumes it already has a valid string — which is
/// exactly the shape of bug this session's admin.firestore.FieldValue saga
/// was: a runtime TypeError from an assumption the type checker never saw.
///
/// These calls bypass `TestSeed.placeOrder`'s typed `String paymentMethodId`
/// parameter ENTIRELY and call the callable directly, because a Dart-typed
/// wrapper cannot construct a call with a non-string value in that slot —
/// the whole point here is to send what a modified client or a replayed,
/// hand-crafted request could send, not what this app's own UI would ever
/// construct.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestSeed seed;

  setUpAll(() async {
    await initializeIntegrationFirebase();
  });

  setUp(() async {
    seed = TestSeed.instance();
    await seed.clearAll();
  });

  /// Calls placeOrder directly with an arbitrary, possibly non-string,
  /// paymentMethodId — and whatever else the caller wants malformed.
  Future<FirebaseFunctionsException?> callWithRawPayment(
    dynamic paymentMethodId,
    String productId, {
    dynamic quantity = 1,
    dynamic idempotencyKey,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('placeOrder')
          .call<Map<String, dynamic>>({
        'idempotencyKey': idempotencyKey ??
            'raw-${DateTime.now().microsecondsSinceEpoch}',
        'items': [
          {'productId': productId, 'quantity': quantity},
        ],
        'addressId': 'addr_1',
        'paymentMethodId': paymentMethodId,
      });
      return null; // succeeded — itself a finding if that was unexpected
    } on FirebaseFunctionsException catch (e) {
      return e;
    }
  }

  /// Sets up one verified buyer and one product, ready to attempt an order.
  Future<String> readyProduct() async {
    final sellerId = await seed.seedSeller();
    final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);
    final buyerId = await seed.signInReadyBuyer();
    await seed.markPhoneVerified(buyerId);
    return productId;
  }

  group('Type confusion on paymentMethodId — must be invalid-argument, '
      'never internal', () {
    testWidgets('null is refused as a type error, not a crash', (
      tester,
    ) async {
      final productId = await readyProduct();
      final error = await callWithRawPayment(null, productId);

      expect(error, isNotNull);
      expect(
        error!.code,
        'invalid-argument',
        reason: 'typeof null === "object" in JavaScript, so this must fail '
            'the typeof check before ever reaching the allow-list — if this '
            'instead throws "internal", something downstream is calling a '
            'string method on null',
      );
    });

    testWidgets('a number is refused as a type error', (tester) async {
      final productId = await readyProduct();
      final error = await callWithRawPayment(1, productId);

      expect(error, isNotNull);
      expect(error!.code, 'invalid-argument');
    });

    testWidgets('a boolean is refused as a type error', (tester) async {
      final productId = await readyProduct();
      final error = await callWithRawPayment(true, productId);

      expect(error, isNotNull);
      expect(error!.code, 'invalid-argument');
    });

    testWidgets('an array is refused as a type error, not silently unwrapped',
        (tester) async {
      final productId = await readyProduct();
      final error =
          await callWithRawPayment(['cash_on_delivery'], productId);

      expect(error, isNotNull);
      expect(
        error!.code,
        'invalid-argument',
        reason: 'a single-element array containing a legal value must NOT '
            'be treated as equivalent to the string itself — that would '
            'mean somewhere a loose comparison or a stringly-typed check is '
            'doing implicit coercion',
      );
    });

    testWidgets('a plain object is refused as a type error', (tester) async {
      final productId = await readyProduct();
      final error = await callWithRawPayment(
        {'method': 'cash_on_delivery'},
        productId,
      );

      expect(error, isNotNull);
      expect(error!.code, 'invalid-argument');
    });

    testWidgets('an entirely missing paymentMethodId is a type error too',
        (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);
      final buyerId = await seed.signInReadyBuyer();
      await seed.markPhoneVerified(buyerId);

      FirebaseFunctionsException? error;
      try {
        await FirebaseFunctions.instance
            .httpsCallable('placeOrder')
            .call<Map<String, dynamic>>({
          'idempotencyKey':
              'raw-missing-${DateTime.now().microsecondsSinceEpoch}',
          'items': [
            {'productId': productId, 'quantity': 1},
          ],
          'addressId': 'addr_1',
          // paymentMethodId omitted entirely.
        });
      } on FirebaseFunctionsException catch (e) {
        error = e;
      }

      expect(error, isNotNull);
      expect(
        error!.code,
        'invalid-argument',
        reason: 'request.data?.paymentMethodId resolves to undefined, and '
            'typeof undefined !== "string" — this must be caught the same '
            'way an explicit null is',
      );
    });
  });

  group('Value confusion on paymentMethodId — a well-typed string that is '
      'still not allowed', () {
    testWidgets('an unrecognised rail name is failed-precondition, not '
        'invalid-argument', (tester) async {
      final productId = await readyProduct();
      final error = await callWithRawPayment('totally_made_up', productId);

      expect(error, isNotNull);
      expect(
        error!.code,
        'failed-precondition',
        reason: 'the type check passes — this IS a string — so the '
            'allow-list is what must refuse it. Getting invalid-argument '
            'here instead would mean the allow-list check never ran, which '
            'is a different, more concerning failure than the message '
            'suggests',
      );
    });

    testWidgets('case sensitivity is not silently forgiving', (tester) async {
      final productId = await readyProduct();
      final error =
          await callWithRawPayment('CASH_ON_DELIVERY', productId);

      expect(error, isNotNull);
      expect(
        error!.code,
        'failed-precondition',
        reason: 'Set.has() is exact-match; if this SUCCEEDS instead, the '
            'server is doing a case-insensitive comparison somewhere that '
            'was never intended, which widens the allow-list beyond what '
            'PHASE_1_ALLOWED_PAYMENT_METHODS actually declares',
      );
    });

    testWidgets(
      'padded whitespace around a legal value still succeeds — this is the '
      'ONE case that should NOT fail',
      (tester) async {
        // The complement of the tests above: placeOrder.ts explicitly calls
        // .trim() before the Set lookup, so a value a real client might
        // accidentally send with incidental whitespace should not be
        // punished for it. Included so this file cannot be satisfied by an
        // over-strict change that breaks the trim behaviour while chasing
        // the other findings.
        final productId = await readyProduct();
        final error =
            await callWithRawPayment('  cash_on_delivery  ', productId);

        expect(
          error,
          isNull,
          reason: 'cleanPaymentMethodId = paymentMethodId.trim() should '
              'make this equivalent to the exact allowed value',
        );
      },
    );

    testWidgets(
      'an embedded null byte does not smuggle a match past the allow-list',
      (tester) async {
        final productId = await readyProduct();
        // \u0000 survives .trim() (trim only strips whitespace), so this
        // must fail the exact Set.has() comparison rather than being
        // truncated somewhere into a match.
        final error = await callWithRawPayment(
          'cash_on_delivery\u0000',
          productId,
        );

        expect(error, isNotNull);
        expect(error!.code, 'failed-precondition');
      },
    );
  });

  group('Adjacent type confusion — quantity, same "trust the client type" '
      'theme', () {
    // Grounded on computeOrder's own handling, seen in full earlier this
    // session: `Math.floor(Number(line.quantity))`, checked with
    // Number.isFinite and >= 1. Included here rather than in a separate
    // file because it is the same class of bug on an adjacent field, not
    // because it belongs to the payment gate specifically.

    testWidgets('a numeric-STRING quantity is coerced safely, not refused',
        (tester) async {
      final productId = await readyProduct();
      final error = await callWithRawPayment(
        'cash_on_delivery',
        productId,
        quantity: '2', // string, not int
      );

      expect(
        error,
        isNull,
        reason: 'Number("2") === 2 — this is intentionally permissive '
            'coercion, not a bug, and this test exists so a future '
            'tightening of quantity validation does not accidentally break '
            'a legitimate numeric-string client value',
      );
    });

    testWidgets('a non-numeric quantity string is invalid-argument, not a '
        'crash', (tester) async {
      final productId = await readyProduct();
      final error = await callWithRawPayment(
        'cash_on_delivery',
        productId,
        quantity: 'a lot please',
      );

      expect(
        error,
        isNotNull,
        reason: 'Number("a lot please") is NaN, and NaN >= 1 is false — '
            'this should surface as invalid-argument from computeOrder, not '
            'as an internal error from an unguarded arithmetic operation '
            'downstream',
      );
    });

    testWidgets('a negative quantity is refused, not silently flipped '
        'positive', (tester) async {
      final productId = await readyProduct();
      final error =
          await callWithRawPayment('cash_on_delivery', productId, quantity: -1);

      expect(error, isNotNull);
    });

    testWidgets('a zero quantity is refused', (tester) async {
      final productId = await readyProduct();
      final error =
          await callWithRawPayment('cash_on_delivery', productId, quantity: 0);

      expect(error, isNotNull);
    });
  });
}
