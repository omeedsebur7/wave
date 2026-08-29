import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/seed.dart';
import 'helpers/test_bootstrap.dart';

/// Security abuse test, round 2: ORDER STATE-MACHINE BYPASS.
///
/// firestore.rules gives the seller exactly these transitions, via
/// sellerTransitionAllowed():
///
///   confirmed        -> packed, cancelled
///   packed           -> handedToCourier, cancelled
///   handedToCourier  -> outForDelivery, delivered
///   outForDelivery   -> delivered
///
/// and the buyer exactly one: status -> 'cancelled', only from
/// pendingPayment/confirmed/packed.
///
/// Every pair NOT in that table is what this file tries. A skipped state is
/// not a cosmetic shortcut — per purchase_flow_test.dart's own reasoning,
/// confirmed -> delivered would close the buyer's cancellation window
/// without the intervening states ever existing, and unlock a rating on an
/// order that, as far as any other check can tell, never shipped.
///
/// Every test here uses `seed.clientUpdate` / `seed.setOrderStatus` — normal
/// client SDK writes, fully subject to rules — never `forceStatus`, which is
/// the admin REST bypass and would prove nothing about the rule.
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

  /// Seeds a confirmed order and returns (orderId, sellerId), with the SELLER
  /// left signed in — the identity every illegal-transition attempt below
  /// needs, since sellerTransitionAllowed only applies to
  /// resource.data.seller_id == request.auth.uid in the first place.
  Future<({String orderId, String sellerId})> confirmedOrderAsSeller() async {
    final sellerId = await seed.signInAsSeller();
    final productId = await seed.seedProduct(sellerId: sellerId);
    final orderId = await seed.seedConfirmedOrder(
      sellerId: sellerId,
      productId: productId,
    );
    // Guards the promise this helper's own doc comment makes.
    //
    // The first version of this file said it would "reassert explicitly" and
    // then returned without doing so. Two tests failed with
    // permission-denied on transitions that should have been legal — which
    // reads as a rules bug and is not one. FirebaseAuth's session survives
    // across tests in a single file (setUp rebuilds TestSeed but never
    // touches auth), so a prior test leaving a buyer signed in silently
    // breaks every seller transition that follows.
    //
    // Throwing names the real problem instead of letting Firestore report a
    // generic denial several lines later.
    final active = seed.currentUid;
    if (active != sellerId) {
      throw StateError(
        'confirmedOrderAsSeller must leave seller $sellerId signed in, but '
        'the active session is $active. Something between signInAsSeller() '
        'and this return replaced the session.',
      );
    }

    return (orderId: orderId, sellerId: sellerId);
  }

  group('Illegal seller transitions — skipping states entirely', () {
    testWidgets('confirmed cannot jump straight to delivered', (
      tester,
    ) async {
      final o = await confirmedOrderAsSeller();
      await expectLater(
        seed.setOrderStatus(o.orderId, 'delivered'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: "skips packed and handedToCourier — the buyer's "
            'cancellation window would close with no warning, and a rating '
            'would unlock on an order that never shipped',
      );
      expect((await seed.order(o.orderId))!['status'], 'confirmed');
    });

    testWidgets('confirmed cannot jump straight to handedToCourier', (
      tester,
    ) async {
      final o = await confirmedOrderAsSeller();
      await expectLater(
        seed.setOrderStatus(o.orderId, 'handedToCourier'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );
      expect((await seed.order(o.orderId))!['status'], 'confirmed');
    });

    testWidgets('confirmed cannot jump straight to outForDelivery', (
      tester,
    ) async {
      final o = await confirmedOrderAsSeller();
      await expectLater(
        seed.setOrderStatus(o.orderId, 'outForDelivery'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );
      expect((await seed.order(o.orderId))!['status'], 'confirmed');
    });

    testWidgets('packed cannot jump straight to delivered', (tester) async {
      final o = await confirmedOrderAsSeller();
      await seed.setOrderStatus(o.orderId, 'packed');

      await expectLater(
        seed.setOrderStatus(o.orderId, 'delivered'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );
      expect((await seed.order(o.orderId))!['status'], 'packed');
    });

    testWidgets('packed cannot jump straight to outForDelivery', (
      tester,
    ) async {
      final o = await confirmedOrderAsSeller();
      await seed.setOrderStatus(o.orderId, 'packed');

      await expectLater(
        seed.setOrderStatus(o.orderId, 'outForDelivery'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );
      expect((await seed.order(o.orderId))!['status'], 'packed');
    });
  });

  group('Illegal seller transitions — moving backwards', () {
    testWidgets('handedToCourier cannot revert to packed', (tester) async {
      final o = await confirmedOrderAsSeller();
      await seed.setOrderStatus(o.orderId, 'packed');
      await seed.setOrderStatus(o.orderId, 'handedToCourier');

      // A seller reverting a shipped order back could reopen a window that
      // was correctly closed — the cancellation gate reads status, not
      // history.
      await expectLater(
        seed.setOrderStatus(o.orderId, 'packed'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );
      expect((await seed.order(o.orderId))!['status'], 'handedToCourier');
    });

    testWidgets('outForDelivery cannot revert to handedToCourier', (
      tester,
    ) async {
      final o = await confirmedOrderAsSeller();
      await seed.setOrderStatus(o.orderId, 'packed');
      await seed.setOrderStatus(o.orderId, 'handedToCourier');
      await seed.setOrderStatus(o.orderId, 'outForDelivery');

      await expectLater(
        seed.setOrderStatus(o.orderId, 'handedToCourier'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );
      expect((await seed.order(o.orderId))!['status'], 'outForDelivery');
    });
  });

  group('Terminal states cannot be re-entered', () {
    // "The rewrite of the resolveReport race exists because a write with no
    // re-check is exactly how a lost race sticks" — the same shape of bug
    // applies here if delivered/cancelled/refunded are not genuinely dead
    // ends: a seller could bounce an order OUT of a rateable state to erase
    // a bad rating, which is the specific attack purchase_flow_test.dart's
    // header names for delivered being terminal.

    testWidgets('delivered cannot transition anywhere, including back to '
        'itself', (tester) async {
      final o = await confirmedOrderAsSeller();
      await seed.setOrderStatus(o.orderId, 'packed');
      await seed.setOrderStatus(o.orderId, 'handedToCourier');
      await seed.setOrderStatus(o.orderId, 'delivered');

      for (final target in [
        'confirmed',
        'packed',
        'handedToCourier',
        'outForDelivery',
        'cancelled',
        'delivered', // even a no-op re-write to the same terminal state
      ]) {
        await expectLater(
          seed.setOrderStatus(o.orderId, target),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
          reason: 'delivered -> $target must be refused; sellerTransitionAllowed '
              'has no entries starting from delivered at all',
        );
      }
      expect((await seed.order(o.orderId))!['status'], 'delivered');
    });

    testWidgets('cancelled cannot be reopened by the seller', (tester) async {
      final o = await confirmedOrderAsSeller();

      // NOT seed.setOrderStatus() for the legitimate cancel.
      //
      // The seller `allow update` rule requires, when the new status is
      // 'cancelled': request.resource.data.cancelled_by == 'seller'.
      // setOrderStatus() only ever writes {'status': status} — it has no
      // idea cancellation carries a second required field, because every
      // OTHER transition it is used for (packed, handedToCourier, ...)
      // doesn't need one. Using it here made the legitimate SETUP step fail
      // with permission-denied, before the actual illegal-transition
      // assertion below ever ran — which reads exactly like the rule under
      // test rejecting something it should have allowed.
      await seed.clientUpdate('orders/${o.orderId}', {
        'status': 'cancelled',
        'cancelled_by': 'seller',
      });

      await expectLater(
        seed.setOrderStatus(o.orderId, 'packed'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'a cancelled order coming back to life could let a seller '
            'fulfil something the buyer believes they walked away from, '
            'with no fresh consent',
      );
      expect(await seed.adminOrderStatus(o.orderId), 'cancelled');
    });
  });

  group('A status outside the enum entirely', () {
    testWidgets('an unrecognised status string is refused, not merely '
        'unhandled', (tester) async {
      final o = await confirmedOrderAsSeller();

      // sellerTransitionAllowed does string equality against a fixed set of
      // literals — 'confirmed', 'packed', etc. Nothing in the rule
      // constrains the OUTGOING value to be a member of any enum; it is
      // whatever the client sends. A status your own app has never heard of
      // reaching Firestore is exactly the kind of state that breaks every
      // downstream switch statement silently, because no `default` case is
      // watching for it — see order_detail_page.dart's own
      // no_default_cases lint.
      await expectLater(
        seed.setOrderStatus(o.orderId, 'shipped_via_teleporter'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: '"confirmed" is not in sellerTransitionAllowed\'s '
            "(from: 'confirmed').to list, so this should fail on the SAME "
            'ground as any other illegal target — worth confirming rather '
            "than assuming, since a typo'd literal in the rule would let "
            'anything through silently',
      );
      expect((await seed.order(o.orderId))!['status'], 'confirmed');
    });
  });

  group('Wrong identity attempting a transition', () {
    testWidgets('a seller cannot transition an order that is not theirs', (
      tester,
    ) async {
      final realSeller = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: realSeller);
      final orderId = await seed.seedConfirmedOrder(
        sellerId: realSeller,
        productId: productId,
      );

      // A different, genuinely unrelated seller.
      await seed.signInAsSeller();

      await expectLater(
        seed.setOrderStatus(orderId, 'packed'),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'resource.data.seller_id == request.auth.uid must hold — '
            "otherwise any seller could pack, ship, or deliver a stranger's "
            'order',
      );
      // Read through admin REST, NOT seed.order().
      //
      // seed.order() is a client read, and the orders read rule requires
      // buyer_id or seller_id to match request.auth.uid. The attacker signed
      // in above is neither, so that read is refused — correctly, and by a
      // DIFFERENT rule than the one under test. The first version of this
      // test used seed.order() and failed on the VERIFICATION step rather
      // than on the attempted write, which reads as though the transition
      // rule let something through when in fact the read rule was working.
      expect(await seed.adminOrderStatus(orderId), 'confirmed');
    });

    testWidgets(
      'the buyer cannot perform a SELLER transition, even a legal one',
      (tester) async {
        final sellerId = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: sellerId);
        final buyerId = await seed.signInReadyBuyer();
        final orderId = await seed.seedConfirmedOrder(
          sellerId: sellerId,
          productId: productId,
          buyerId: buyerId,
        );

        // confirmed -> packed is a legal transition FOR THE SELLER. This
        // proves the buyer's separate update rule does not also, even
        // accidentally, grant seller-shaped transitions — the two `allow
        // update` blocks in firestore.rules are meant to be strictly
        // disjoint in what they permit.
        await expectLater(
          seed.setOrderStatus(orderId, 'packed'),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        );
        expect((await seed.order(orderId))!['status'], 'confirmed');
      },
    );
  });

  group('Buyer cancellation window — beyond what purchase_flow_test covers',
      () {
    testWidgets('the buyer cannot cancel once delivered', (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId);
      final buyerId = await seed.signInReadyBuyer();
      final orderId = await seed.seedDeliveredOrder(
        buyerId: buyerId,
        sellerId: sellerId,
        productId: productId,
      );

      await expectLater(
        seed.cancelAsBuyer(orderId),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'resource.data.status in [pendingPayment, confirmed, '
            'packed] excludes delivered — cancelling a delivered order is a '
            'refund conversation, not a status flip',
      );
    });

    testWidgets('the buyer cannot cancel a cancelled order a second time', (
      tester,
    ) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId);
      final buyerId = await seed.signInReadyBuyer();
      final orderId = await seed.seedConfirmedOrder(
        sellerId: sellerId,
        productId: productId,
        buyerId: buyerId,
      );

      await seed.cancelAsBuyer(orderId);

      await expectLater(
        seed.cancelAsBuyer(orderId),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'resource.data.status in [...] excludes cancelled itself, '
            'so a second cancel call must fail rather than silently no-op — '
            'a no-op here would be indistinguishable from a bug that '
            'accepts writes with no actual effect',
      );
    });

    testWidgets('cancelling as the buyer cannot smuggle a status other '
        'than "cancelled"', (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId);
      final buyerId = await seed.signInReadyBuyer();
      final orderId = await seed.seedConfirmedOrder(
        sellerId: sellerId,
        productId: productId,
        buyerId: buyerId,
      );

      // request.resource.data.status == 'cancelled' is a fixed literal, not
      // merely "status changed" — this tries setting it to something a
      // buyer has no business setting, using the exact write shape a
      // legitimate cancel would otherwise use.
      await expectLater(
        seed.clientUpdate(
          'orders/$orderId',
          {
            'status': 'delivered',
            'cancelled_by': 'buyer',
          },
        ),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'a buyer marking their own order "delivered" would unlock a '
            'rating prompt and close the cancellation window on an order '
            'nobody shipped',
      );
    });
  });
}
