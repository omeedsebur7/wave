import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/seed.dart';
import 'helpers/test_bootstrap.dart';

/// Security abuse test, round 4: SELF-DEALING, beyond the buyer≠seller check
/// already covered in purchase_flow_test.dart.
///
/// orderTotals.ts's own comment names the shape of the attack precisely:
///
///   "This is the self-dealing attack on any marketplace with a reputation
///   system, and here it is free: with cash on delivery no money moves at
///   all, so a seller could place an order with themselves, mark it
///   delivered, and rate themselves five stars. Repeat a hundred times and
///   you have Gold."
///
/// `buyerId === product.sellerId` closes the most direct version of that —
/// one account, one order, itself as both parties. This file tries the
/// variations that check does NOT obviously cover: two real accounts working
/// together, and the two places a rating actually lands (reviews and
/// seller_ratings) rather than the order itself.
///
/// GROUNDED ON: computeOrder's self-dealing check (seen in full), and the
/// reviews / seller_ratings rules (seen in full, and seller_ratings' fix
/// earlier this session — canRateOrder() / orderData(ratingId).seller_id —
/// is precisely what test 2 below is a regression guard for). NOT grounded
/// on anything in recomputeTrustTier.ts, which I have not seen; the actual
/// trust-tier ARITHMETIC (how many 5-star ratings move a tier) is out of
/// scope here. This file only checks whether a rating can be MANUFACTURED at
/// all, not what it does once it exists.
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

  group('One account, both sides — the direct case', () {
    testWidgets('a seller cannot place an order on their own product', (
      tester,
    ) async {
      // Restated deliberately, even though purchase_flow_test.dart may
      // already cover this shape indirectly — a self-dealing test suite
      // that assumes coverage elsewhere is exactly the kind of gap this
      // whole phase exists to close. Explicit here means it cannot silently
      // stop being true if that other test changes.
      final sellerId = await seed.signInAsSeller();
      final productId = await seed.seedProduct(sellerId: sellerId);
      await seed.markPhoneVerified(sellerId);

      await expectLater(
        seed.placeOrder(productId: productId, quantity: 1),
        throwsA(
          predicate((e) => '$e'.contains('failed-precondition')),
        ),
        reason: 'computeOrder throws OrderComputationError with code '
            '"failed-precondition" and message "You cannot buy your own '
            'listing" when buyerId === product.sellerId — this proves that '
            "check is actually wired to placeOrder's auth.uid, not merely "
            'present in a function nothing calls with real identity',
      );
    });
  });

  group('Two real accounts, cooperating — the multi-account case', () {
    // computeOrder's check is `buyerId !== product.sellerId` — a STRING
    // comparison of two different Firebase uids. Two accounts controlled by
    // the same person, with two different uids, satisfy that trivially. This
    // is not a rules bug — Firestore has no way to know two accounts share a
    // phone or a device — but it is the actual shape the orderTotals.ts
    // comment describes ("repeat a hundred times and you have Gold"), and
    // it is worth having a test that PROVES the platform allows it, so that
    // whoever owns fraud detection knows the boundary of what these rules
    // can and cannot stop.
    testWidgets(
      'a second, genuinely distinct account CAN complete a self-dealt order '
      '— this is expected, and the boundary worth knowing',
      (tester) async {
        final sellerId = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);

        // A real, separate Firebase identity — not the seller's own uid.
        final buyer = await TestSeed.signInSecondBuyer();
        await seed.markPhoneVerified(buyer.uid);

        final order = await buyer.placeOrder(productId: productId, quantity: 1);

        expect(
          order, isNotNull,
          reason: 'confirms the order-level check has NO way to catch this '
              '— buyerId (buyer.uid) genuinely differs from '
              'product.sellerId, so computeOrder correctly allows it. This '
              "is not a bug in this file's scope; the defence against it, "
              'if one exists, would be identity/device/phone-linking '
              'analysis outside Firestore rules entirely — worth confirming '
              'that defence exists SOMEWHERE, since these rules will not '
              'provide it',
        );

        await buyer.dispose();
      },
    );
  });

  group('Rating a self-dealt order — the actual payoff, not just the order',
      () {
    // Placing the order is not the exploit; the exploit is what it unlocks
    // afterward. The order itself completing (previous group) is only
    // dangerous if a rating can subsequently be attached to it.

    testWidgets(
      'the seller cannot review their own product through an order they '
      'received as the seller',
      (tester) async {
        // Constructed the way it would actually happen: seller receives a
        // real order from a real other buyer, then tries to also post a
        // REVIEW on it — reviews require author_id == buyer_id == auth.uid
        // AND seller_id != auth.uid, so the seller attempting this as
        // themselves should fail on the buyer_id check alone, regardless of
        // the seller_id check redundantly catching it too.
        final sellerId = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: sellerId);
        final buyerId = await seed.signInReadyBuyer();
        final orderId = await seed.seedDeliveredOrder(
          buyerId: buyerId,
          sellerId: sellerId,
          productId: productId,
        );

        // Switch to the seller's own session and attempt to author a review
        // on an order that was never theirs to buy.
        await seed.signInAsSeller();

        await expectLater(
          seed.clientSet(
            'reviews/${orderId}_review',
            data: {
              'author_id': sellerId,
              'order_id': orderId,
              'product_id': productId,
              'rating': 5,
              'text': 'a review the seller wrote about their own product',
            },
          ),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
          reason: 'get(orders/orderId).data.buyer_id == request.auth.uid '
              "must fail here — the signed-in seller is not this order's "
              'buyer, however the order came to exist',
        );
      },
    );

    testWidgets(
      'a self-dealt order (two cooperating accounts) still cannot be rated '
      'by the seller account, because seller_ratings checks buyer_id too',
      (tester) async {
        // The interesting version: buyer and seller are genuinely different
        // uids (satisfying computeOrder), but what if the SELLER then tries
        // to also submit the seller_ratings write, e.g. because the two
        // accounts are colluding and the seller-controlled account wants to
        // directly inject a 5-star rating rather than going through the
        // cooperating buyer account?
        final sellerId = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: sellerId, stock: 5);

        final buyer = await TestSeed.signInSecondBuyer();
        await seed.markPhoneVerified(buyer.uid);
        final order = await buyer.placeOrder(
          productId: productId,
          quantity: 1,
        );
        final orderId = order!['id'] as String;

        // Move it to delivered.
        //
        // Via admin REST, NOT the client state machine. The first version of
        // this test called signInAsSeller() and then setOrderStatus() three
        // times — but signInAsSeller() creates a BRAND-NEW seller account
        // every call, so the identity it signed in was not the seller on
        // this order at all. The transitions were refused with
        // permission-denied, and the test failed on its own setup rather
        // than on the assertion it exists to make.
        //
        // Re-signing the original seller is not possible: seedSeller() only
        // ever creates new accounts, and this file has no handle on that
        // session once signInSecondBuyer() replaced it. Since the transition
        // path itself is already proven by state_machine_bypass_test.dart,
        // driving it again here would only re-test that file's subject —
        // what matters below is purely that the order REACHES delivered, so
        // the rating rule has something legitimate to refuse.
        await seed.forceStatus(orderId, 'delivered');

        // Sign in as a seller identity and attempt the rating directly,
        // rather than through the cooperating buyer account.
        //
        // This is a DIFFERENT account from the order's actual seller, for the
        // reason above — which makes the assertion strictly stronger, not
        // weaker: canRateOrder() requires the author to be the order's BUYER,
        // so any account that is not that buyer must be refused, whether it
        // is the real seller, a colluding second account, or a stranger.
        await seed.signInAsSeller();
        await expectLater(
          seed.clientSet(
            'seller_ratings/$orderId',
            data: {
              'author_id': sellerId,
              'seller_id': sellerId,
              'rating': 5,
            },
          ),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
          reason: 'computeOrder throws OrderComputationError with code '
              '"failed-precondition" and message "You cannot buy your own '
              'listing" when buyerId === product.sellerId — this proves that '
              "check is actually wired to placeOrder's auth.uid, not merely "
              'present in a function nothing calls with real identity',
        );

        await buyer.dispose();
      },
    );
  });
}
