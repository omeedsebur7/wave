import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wave/core/config/emulator.dart';
import 'package:wave/firebase_options.dart';

import 'helpers/seed.dart';

/// Purchase flow integration test (§6).
///
/// Run against the Firebase emulator suite, never production:
///
///     firebase emulators:start --only auth,firestore,functions
///     flutter test integration_test/purchase_flow_test.dart \
///       --dart-define=USE_EMULATOR=true
///
/// On a physical device add the host machine's LAN address, because the phone
/// cannot reach the emulator on localhost:
///
///       --dart-define=EMULATOR_HOST=192.168.1.x
///
/// and start the suite with `--host 0.0.0.0` so it binds beyond 127.0.0.1.
///
/// These exercise the DATA layer end to end — repositories, Cloud Functions,
/// Security Rules — rather than driving widgets. That is deliberate: the
/// failures worth catching here (double-charging, a gate that can be skipped,
/// stock going negative) live below the UI, and a widget-driven test would
/// couple them to a button's position.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestSeed seed;

  setUpAll(() async {
    // bootstrap.dart does this for the app, but an integration test IS the
    // entry point — main.dart never runs — so without it the first
    // FirebaseFirestore.instance in TestSeed throws [core/no-app] and every
    // test in the file fails identically before touching any real logic.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // HARD STOP, not a convenience check.
    //
    // setUp calls seed.clearAll(), which deletes every document in ten
    // collections. Against a real project that is not a failing test, it is
    // data loss with no undo. The flag is the only thing distinguishing the
    // two, so a missing flag must abort rather than default to "probably
    // local" — the failure mode of guessing wrong here is unrecoverable and
    // the failure mode of being strict is a one-line command fix.
    const useEmulator =
        bool.fromEnvironment('USE_EMULATOR');
    if (!useEmulator) {
      throw StateError(
        'Refusing to run: --dart-define=USE_EMULATOR=true was not passed. '
        'These tests wipe entire collections and must never touch a real '
        'project. Start the suite with '
        '`firebase emulators:start --only auth,firestore,functions` and '
        'rerun with the flag.',
      );
    }

    // Mirrors main.dart's wiring, including EMULATOR_HOST — Android reaches
    // the host machine on 10.0.2.2 rather than localhost, and a physical
    // device needs the LAN address. Hardcoding localhost would connect on a
    // desktop run and silently fail on a phone, which is worse than failing
    // everywhere: it passes in one place and breaks in the one nobody tested.
    const host = String.fromEnvironment(
      'EMULATOR_HOST',
      defaultValue: 'localhost',
    );
    await FirebaseAuth.instance.useAuthEmulator(host, EmulatorConfig.authPort);
    FirebaseFirestore.instance
        .useFirestoreEmulator(host, EmulatorConfig.firestorePort);
    FirebaseFunctions.instance
        .useFunctionsEmulator(host, EmulatorConfig.functionsPort);
  });

  setUp(() async {
    seed = TestSeed.instance();
    // Shared state between tests produces order-dependent flakes, which are
    // the most expensive kind to chase.
    await seed.clearAll();
  });

  group('Buy Now on Reel — the core conversion path (§5.1)', () {
    testWidgets('a verified buyer completes a purchase from a Reel',
        (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);
      final reelId =
          await seed.seedReel(authorId: sellerId, linkedProductId: productId);
      final buyerId = await seed.signInReadyBuyer();
      await seed.markPhoneVerified(buyerId);

      final order = await seed.placeOrder(
        productId: productId,
        quantity: 1,
        sourceReelId: reelId,
      );

      expect(order, isNotNull);
      // The Reel that produced the sale must be recorded, or the Buy-Now
      // funnel cannot be joined back to its source.
      expect(order!['source_reel_id'], reelId);
      expect(order['buyer_id'], buyerId);
      expect(order['status'], 'confirmed');
      expect(await seed.stockOf(productId), 4);
    });

    testWidgets('an unverified buyer is refused before any charge',
        (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);
      // Deliberately NOT calling markPhoneVerified. signInReadyBuyer used to
      // do it internally, which made this test unable to fail — it sailed
      // through the gate it exists to prove and reported an unrelated error
      // from further down.
      await seed.signInReadyBuyer();

      await expectLater(
        seed.placeOrder(productId: productId, quantity: 1),
        throwsA(predicate((e) => '$e'.contains('failed-precondition'))),
      );

      // Nothing may have moved: no order, and stock untouched.
      expect(await seed.orderCount(), 0);
      expect(await seed.stockOf(productId), 5);
    });

    testWidgets('a retried submit with the same key creates ONE order',
        (tester) async {
      // The single most expensive bug this app could ship.
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);
      final buyerId = await seed.signInReadyBuyer();
      await seed.markPhoneVerified(buyerId);

      const key = 'idem-key-fixed-for-this-test';
      final first = await seed.placeOrder(
        productId: productId,
        quantity: 1,
        idempotencyKey: key,
      );
      final second = await seed.placeOrder(
        productId: productId,
        quantity: 1,
        idempotencyKey: key,
      );

      expect(await seed.orderCount(), 1);
      expect(second!['id'], first!['id']);
      // Stock decremented once, not twice — the replay must not re-run the
      // side effects, only return the original result.
      expect(await seed.stockOf(productId), 4);
    });

    testWidgets('two different keys create two orders', (tester) async {
      // The complement of the test above: idempotency must not be so eager
      // that a genuine second purchase is swallowed.
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);
      final buyerId = await seed.signInReadyBuyer();
      await seed.markPhoneVerified(buyerId);

      // Both at least 8 characters: placeOrder rejects anything shorter with
      // "Missing idempotency key", and the previous 'key-a' / 'key-b' were
      // five. The test failed on a length check while appearing to fail on
      // wiring.
      await seed.placeOrder(
        productId: productId,
        quantity: 1,
        idempotencyKey: 'idem-key-alpha',
      );
      await seed.placeOrder(
        productId: productId,
        quantity: 1,
        idempotencyKey: 'idem-key-bravo',
      );

      expect(await seed.orderCount(), 2);
      expect(await seed.stockOf(productId), 3);
    });

    testWidgets('the price comes from the catalogue, not the request',
        (tester) async {
      // A client that could send its own total could buy anything for
      // anything.
      final sellerId = await seed.seedSeller();
      final productId =
          await seed.seedProduct(sellerId: sellerId, priceMinor: 50000);
      final buyerId = await seed.signInReadyBuyer();
      await seed.markPhoneVerified(buyerId);

      final order = await seed.placeOrder(
        productId: productId,
        quantity: 2,
        // Ignored by placeOrder, which recomputes from the product document.
        claimedTotalMinor: 1,
      );

      expect(order!['total_minor'], 100000);
    });

    testWidgets('an order beyond available stock is refused', (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId, stock: 2);
      final buyerId = await seed.signInReadyBuyer();
      await seed.markPhoneVerified(buyerId);

      await expectLater(
        seed.placeOrder(productId: productId, quantity: 3),
        throwsA(predicate((e) => '$e'.contains('out-of-range'))),
      );
      expect(await seed.stockOf(productId), 2);
    });

    testWidgets('a guest cannot place an order at all', (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId);
      await seed.signInGuest();

      await expectLater(
        seed.placeOrder(productId: productId, quantity: 1),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );
    });

    group('Phase 1 accepts only cash on delivery', () {
      // The UI-level rail picker only ever offers cash — see
      // PaymentRail.phase1EnabledRails — but a picker is a suggestion, not a
      // boundary. These prove the SERVER refuses anything else, which is the
      // check that actually matters: a modified client, a replayed request, or
      // a future regression that widens the picker must not be able to create
      // a real order — with a real stock decrement and a real seller
      // notification — sitting in `pendingPayment` forever with no webhook in
      // this phase to ever confirm it.

      testWidgets('cash on delivery succeeds', (tester) async {
        final sellerId = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);
        final buyerId = await seed.signInReadyBuyer();
        await seed.markPhoneVerified(buyerId);

        final order = await seed.placeOrder(
          productId: productId,
          quantity: 1,
        );

        expect(order!['status'], 'confirmed');
        expect(await seed.stockOf(productId), 4);
      });

      testWidgets('a paused rail is refused, and nothing moves',
          (tester) async {
        final sellerId = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);
        final buyerId = await seed.signInReadyBuyer();
        await seed.markPhoneVerified(buyerId);

        await expectLater(
          seed.placeOrder(
            productId: productId,
            quantity: 1,
            paymentMethodId: 'zaincash_wallet_1',
          ),
          throwsA(predicate((e) => '$e'.contains('failed-precondition'))),
        );

        // Confirms the rejection happens BEFORE any side effect — stock must
        // be untouched, and no order document should exist for this attempt.
        expect(await seed.stockOf(productId), 5);
        expect(await seed.orderCount(), 0);
      });

      testWidgets('an unrecognised payment method is refused the same way',
          (tester) async {
        // Not just known-but-paused rails — anything that is not literally
        // "cash_on_delivery" is refused. A typo or a made-up value must fail
        // exactly like a real rail would, not be silently accepted because it
        // matched nothing.
        final sellerId = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: sellerId);
        final buyerId = await seed.signInReadyBuyer();
        await seed.markPhoneVerified(buyerId);

        await expectLater(
          seed.placeOrder(
            productId: productId,
            quantity: 1,
            paymentMethodId: 'totally_made_up',
          ),
          throwsA(predicate((e) => '$e'.contains('failed-precondition'))),
        );
      });
    });
  });

  group('Concurrent purchases cannot oversell stock', () {
    // The single most expensive bug this app could ship — sharing that title
    // with the double-submit test earlier in this file, because they guard
    // against the same failure from two different directions. That test fires
    // the SAME buyer twice, sequentially, to prove a retried request cannot
    // double-charge. This one fires TWO buyers at the same instant to prove a
    // genuine race cannot double-sell.
    //
    // The two are not redundant. A sequential double-submit is caught by
    // idempotency alone and says nothing about what happens when Firestore has
    // to reconcile two transactions that both read the same stock count before
    // either had written anything back — which is exactly the shape of two
    // people tapping Buy Now on the last unit of something popular at the same
    // moment, and is a normal Tuesday for a marketplace, not an edge case.

    testWidgets(
      'exactly one buyer gets the last unit when two race for it',
      (tester) async {
        final sellerId = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: sellerId, stock: 1);

        final buyerAId = await seed.signInReadyBuyer();
        await seed.markPhoneVerified(buyerAId);

        // A second buyer needs a genuinely separate identity — see the note on
        // TestSeed.signInSecondBuyer for why signInReadyBuyer cannot do this.
        final buyerB = await TestSeed.signInSecondBuyer();
        await seed.markPhoneVerified(buyerB.uid);

        // Fired together with Future.wait rather than one after another. Two
        // sequential awaits would let the first transaction fully commit
        // before the second even starts reading, which tests a lock, not a
        // race — the two calls have to genuinely overlap in time for this to
        // exercise Firestore's optimistic-concurrency retry rather than mere
        // ordering.
        final results = await Future.wait([
          seed.placeOrder(productId: productId, quantity: 1).catchError(
                (Object e) => <String, dynamic>{'error': '$e'},
              ),
          buyerB.placeOrder(productId: productId, quantity: 1).catchError(
                (Object e) => <String, dynamic>{'error': '$e'},
              ),
        ]);

        final succeeded =
            results.where((r) => r != null && !r.containsKey('error'));
        final failed = results.where(
          (r) => r == null || r.containsKey('error'),
        );

        // Exactly one order for exactly one unit of stock. Not "at most one" —
        // a system that let both buyers walk away thinking they had failed
        // would be safe from overselling and useless as a marketplace.
        expect(
          succeeded.length,
          1,
          reason: 'stock was 1; exactly one buyer must succeed, not zero '
              'and not both',
        );
        expect(failed.length, 1);

        // The loser's failure must name the reason a buyer or a support agent
        // could act on — out of stock — not surface as some other error that
        // makes the two-second loss of a race look like a broken checkout.
        final loser = failed.single;
        expect(
          loser,
          isNotNull,
          reason: 'the losing call returned null rather than an error, so the '
              'reason below cannot be checked at all',
        );
        expect('${loser!['error']}', contains('out of stock'));

        // The ledger agrees with what actually happened: one order recorded,
        // stock at zero, never negative. A transaction that retried
        // internally but left stock decremented twice would pass the
        // "one order" assertion above and still be a real bug.
        expect(await seed.orderCount(), 1);
        expect(await seed.stockOf(productId), 0);

        await buyerB.dispose();
      },
    );
  });

  group('Order lifecycle — the chain the trust system depends on', () {
    testWidgets('confirmed to delivered unlocks exactly one rating',
        (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId);
      final buyerId = await seed.signInReadyBuyer();

      final orderId = await seed.seedDeliveredOrder(
        buyerId: buyerId,
        sellerId: sellerId,
        productId: productId,
      );

      await seed.submitSellerRating(
        orderId: orderId,
        sellerId: sellerId,
        rating: 5,
        // Names the identity this write must happen as. seedSeller and
        // signInReadyBuyer each sign the previous session out, so the active
        // account here is a consequence of line order; without this a drift
        // reports `permission-denied` and reads as a rules bug.
        expectedAuthorId: buyerId,
      );

      final order = await seed.order(orderId);
      expect(order!['has_been_rated'], isTrue);

      // A second rating for the same order must not be accepted, or a buyer
      // could move a seller's tier on their own.
      await expectLater(
        seed.submitSellerRating(
          orderId: orderId,
          sellerId: sellerId,
          rating: 1,
          expectedAuthorId: buyerId,
        ),
        throwsA(anything),
      );
    });

    testWidgets('a seller cannot jump an order straight to delivered',
        (tester) async {
      // Skipping the intermediate states would close the buyer's cancellation
      // window without warning and unlock a rating on something never shipped.
      final sellerId = await seed.signInAsSeller();
      final productId = await seed.seedProduct(sellerId: sellerId);
      final orderId = await seed.seedConfirmedOrder(
        sellerId: sellerId,
        productId: productId,
      );

      await expectLater(
        seed.setOrderStatus(orderId, 'delivered'),
        throwsA(anything),
      );
      expect((await seed.order(orderId))!['status'], 'confirmed');
    });

    testWidgets('the cancellation window closes when the courier takes it',
        (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId);
      final buyerId = await seed.signInReadyBuyer();
      final orderId = await seed.seedConfirmedOrder(
        sellerId: sellerId,
        productId: productId,
        buyerId: buyerId,
      );

      // Open while confirmed.
      await seed.cancelAsBuyer(orderId);
      expect((await seed.order(orderId))!['status'], 'cancelled');

      // Closed once with a courier.
      final second = await seed.seedConfirmedOrder(
        sellerId: sellerId,
        productId: productId,
        buyerId: buyerId,
      );
      await seed.forceStatus(second, 'handedToCourier');
      await expectLater(seed.cancelAsBuyer(second), throwsA(anything));
    });
  });
}
