import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/seed.dart';
import 'helpers/test_bootstrap.dart';

/// Security abuse test, round 1: IDENTITY SPOOFING.
///
/// Every collection in firestore.rules that trusts a FIELD to equal
/// request.auth.uid — author_id, seller_id, reporter_id, sender_id, user_id —
/// rather than the document's own path. A path-based check (users/{userId},
/// blocks/{userId}/...) cannot be spoofed this way: the id IS the identity,
/// and isSelf(userId) reads it directly off the path Firestore already
/// verified. A field-based check can be spoofed by anyone who simply writes a
/// different value into that field — unless the rule actually compares it
/// against request.auth.uid, which is exactly what every test below tries to
/// walk around.
///
/// This category already has a 2-for-2 hit rate in this codebase this
/// session: seller_ratings let a client fake seller_id against the
/// SUBMITTED document rather than the order (fixed — see firestore.rules,
/// canRateOrder()), and notSuspended() denied real users entirely from an
/// unrelated bug in the same review pass. Both were found by reading every
/// rule and asking "what happens if the client just writes something else
/// here" rather than by reasoning about intent.
///
/// Every test in this file follows the same shape:
///   1. Sign in as user A.
///   2. Attempt a client-side write naming user B (or nobody) in the field
///      the rule is supposed to pin to A.
///   3. Assert permission-denied.
///
/// A test that instead needs `seed.clientSet` or `clientUpdate` to SUCCEED is
/// in the wrong file — this file exists to prove refusals, and a helper here
/// returning without throwing is the finding, not a passing test to fix.
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

  group('Reels', () {
    testWidgets('author_id cannot be someone else on create', (tester) async {
      final victim = await seed.seedSeller();
      final attacker = await seed.signInAsSeller();

      final ref = FakeIds.next('reels');
      await expectLater(
        seed.clientSet(
          'reels/$ref',
          data: {
            'author_id': victim, // spoofed — attacker is signed in
            'author_name': 'Attacker',
            'bunny_video_id': 'x',
            'thumbnail_url': 'https://example.test/t.jpg',
            'caption': 'x',
            'caption_lower': 'x',
            'duration_seconds': 10,
            'linked_product_id': null,
            'status': 'published',
            'likes_count': 0,
            'views_count': 0,
            'rank_score': 0,
          },
        ),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'a Reel must be attributable to whoever actually posted it — '
            'attacker $attacker must not be able to publish AS $victim',
      );
    });

    testWidgets(
      'likes_count, views_count, rank_score cannot be set directly on update',
      (tester) async {
        final sellerId = await seed.seedSeller();
        final reelId = await seed.seedReel(authorId: sellerId);
        await seed.signInAsSeller(); // any signed-in user, not necessarily the author

        // Direct writes to any of these three would let a seller fabricate
        // engagement — the exact number a buyer uses to judge whether a Reel
        // is worth trusting.
        for (final field in ['likes_count', 'views_count', 'rank_score']) {
          await expectLater(
            seed.clientUpdate('reels/$reelId', {field: 999999}),
            throwsA(predicate((e) => '$e'.contains('permission-denied'))),
            reason: '$field must only ever move via the sharded-counter '
                'materialisation function, never a direct client write',
          );
        }
      },
    );

    testWidgets('comment author_id cannot be someone else', (tester) async {
      final sellerId = await seed.seedSeller();
      final reelId = await seed.seedReel(authorId: sellerId);
      final victim = await seed.signInReadyBuyer();
      final attacker = await seed.signInReadyBuyer();

      final commentId = FakeIds.next('comments');
      await expectLater(
        seed.clientSet(
          'reels/$reelId/comments/$commentId',
          data: {
            'author_id': victim,
            'text': "putting words in someone else's mouth",
          },
        ),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'attacker $attacker must not be able to post a comment that '
            'reads as having come from $victim',
      );
    });
  });

  group('Products', () {
    testWidgets('seller_id cannot be someone else on create', (tester) async {
      final victim = await seed.seedSeller();
      await seed.signInAsSeller();

      final productId = FakeIds.next('products');
      await expectLater(
        seed.clientSet(
          'products/$productId',
          data: {
            'seller_id': victim,
            'title': 'Not actually theirs',
            'price_minor': 10000,
            'currency': 'IQD',
            'stock': 5,
          },
        ),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'listing a product as another seller would let an attacker '
            "sell under a stranger's trust tier and reputation",
      );
    });

    testWidgets('seller_id cannot be reassigned on update', (tester) async {
      final ownerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: ownerId);
      // No signed-in session with permission to touch this product at all —
      // resource.data.seller_id == request.auth.uid fails immediately, before
      // unchanged('seller_id') is even reached. Included anyway because a
      // rule with the ownership check ordered AFTER the unchanged() checks
      // would behave differently, and that ordering is not obvious from the
      // rule's own text without testing it.
      final attacker = await seed.signInAsSeller();

      await expectLater(
        seed.clientUpdate('products/$productId', {'seller_id': attacker}),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'stealing a listing by reassigning its seller_id must be '
            'refused regardless of which check in the rule catches it first',
      );
    });

    testWidgets(
      'rating_avg, rating_count, sold_count cannot be set directly',
      (tester) async {
        final sellerId = await seed.signInAsSeller();
        final productId = await seed.seedProduct(sellerId: sellerId);

        for (final field in ['rating_avg', 'rating_count', 'sold_count']) {
          await expectLater(
            seed.clientUpdate('products/$productId', {field: 999999}),
            throwsA(predicate((e) => '$e'.contains('permission-denied'))),
            reason: '$field is a materialised aggregate; a seller writing it '
                'directly could fabricate demand to lure buyers',
          );
        }
      },
    );
  });

  group('Reviews', () {
    testWidgets('author_id cannot be someone else on create', (tester) async {
      final sellerId = await seed.seedSeller();
      final productId = await seed.seedProduct(sellerId: sellerId);
      final victim = await seed.signInReadyBuyer();
      final orderId = await seed.seedDeliveredOrder(
        buyerId: victim,
        sellerId: sellerId,
        productId: productId,
      );

      final attacker = await seed.signInReadyBuyer();

      final reviewId = FakeIds.next('reviews');
      await expectLater(
        seed.clientSet(
          'reviews/$reviewId',
          data: {
            'author_id': victim,
            'order_id': orderId,
            'product_id': productId,
            'rating': 1,
            'text': 'a one-star review the real buyer never wrote',
          },
        ),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'attacker $attacker must not be able to post a review that '
            'reads as having come from the actual buyer $victim, positive or '
            'negative — this is a defamation and manipulation vector either '
            'way',
      );
    });
  });

  group('Seller ratings', () {
    // The specific bug this collection had: seller_id was checked against the
    // SUBMITTED document (request.resource.data.seller_id != request.auth.uid)
    // rather than against the order — so an attacker could name literally any
    // seller_id, including a fabricated one nobody was rating, as long as it
    // was not their own uid. Fixed in firestore.rules via canRateOrder() /
    // orderData(ratingId).seller_id. This test is the regression guard.
    testWidgets(
      'seller_id must match the order, not whatever the client submits',
      (tester) async {
        final realSeller = await seed.seedSeller();
        final decoySeller = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: realSeller);
        final buyerId = await seed.signInReadyBuyer();
        final orderId = await seed.seedDeliveredOrder(
          buyerId: buyerId,
          sellerId: realSeller,
          productId: productId,
        );

        await expectLater(
          seed.clientSet(
            'seller_ratings/$orderId',
            data: {
              'author_id': buyerId,
              'seller_id': decoySeller, // does not match the order at all
              'rating': 1,
            },
          ),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
          reason: 'a rating naming a seller who was never party to this '
              'order must be refused regardless of who the buyer actually '
              'is',
        );
      },
    );
  });

  group('Reports', () {
    testWidgets('reporter_id cannot be someone else', (tester) async {
      final sellerId = await seed.seedSeller();
      final reelId = await seed.seedReel(authorId: sellerId);
      final victim = await seed.signInReadyBuyer();
      // Not captured: only the effect (refusal) is asserted below, not the attacker's own uid.
      await seed.signInReadyBuyer();

      final reportId = FakeIds.next('reports');
      await expectLater(
        seed.clientSet(
          'reports/$reportId',
          data: {
            'reporter_id': victim,
            'target_id': reelId,
            'target_type': 'reel',
            'reason': 'spam',
            'action': 'pending',
            'report_count': 1,
          },
        ),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'filing a report AS someone else could be used to make it '
            'look like the victim of harassment reported their own '
            'harasser, muddying any real moderation response',
      );
    });
  });

  group('Chat', () {
    testWidgets(
      'a conversation cannot be created without the creator as a participant',
      (tester) async {
        final userA = await seed.seedSeller();
        // Not captured: this identity's only role is to be signed in when the write below
        // is attempted — the participant_ids payload deliberately omits it.
        await seed.signInAsSeller();

        final conversationId = FakeIds.next('conversations');
        await expectLater(
          seed.clientSet(
            'conversations/$conversationId',
            data: {
              // userB is signed in but not listed — the rule checks
              // `request.auth.uid in request.resource.data.participant_ids`,
              // so this specifically tests that a self-omitted list is
              // refused rather than merely checking for a THIRD party.
              'participant_ids': [userA],
            },
          ),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
          reason: 'a user creating a conversation that does not list '
              'themselves should be refused, not silently allowed to open a '
              'channel they are not verifiably part of',
        );
      },
    );

    testWidgets('message sender_id cannot be someone else', (tester) async {
      final userA = await seed.seedSeller();
      final userB = await seed.signInAsSeller();

      final conversationId = FakeIds.next('conversations');
      await seed.clientSet(
        'conversations/$conversationId',
        data: {
          'participant_ids': [userA, userB],
        },
      );

      final messageId = FakeIds.next('messages');
      await expectLater(
        seed.clientSet(
          'conversations/$conversationId/messages/$messageId',
          data: {
            'sender_id': userA, // userB is signed in, claims to be userA
            'text': 'a message the real userA never sent',
          },
        ),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        reason: 'userB must not be able to send a message that reads as '
            'having come from userA, inside a conversation userB is a '
            'genuine participant of — participation is not the same '
            'permission as impersonation',
      );
    });
  });

  group('Orders — fields no client update may touch', () {
    testWidgets(
      'a buyer cancelling cannot smuggle has_been_rated into the same write',
      (tester) async {
        final sellerId = await seed.seedSeller();
        final productId = await seed.seedProduct(sellerId: sellerId);
        final buyerId = await seed.signInReadyBuyer();
        final orderId = await seed.seedConfirmedOrder(
          sellerId: sellerId,
          productId: productId,
          buyerId: buyerId,
        );

        // The legitimate cancellation fields are status, cancelled_at,
        // cancelled_by, updated_at — hasOnly() should refuse the moment
        // has_been_rated rides along in the SAME write, even though every
        // other field in the payload is one the buyer is allowed to touch.
        await expectLater(
          seed.clientUpdate('orders/$orderId', {
            'status': 'cancelled',
            'cancelled_by': 'buyer',
            'has_been_rated': true,
          }),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
          reason: 'hasOnly() must refuse the whole write when an '
              'out-of-scope field rides along with otherwise-legal ones — a '
              'buyer clearing this flag could rate the same order twice',
        );

        // And the order must be genuinely untouched, not partially applied —
        // Firestore rules are all-or-nothing per write, but this is the
        // assertion that actually proves it rather than assumes it.
        final order = await seed.order(orderId);
        expect(order!['status'], 'confirmed');
      },
    );
  });
}

/// Deterministic-enough ids for documents this file creates directly via
/// clientSet, where there is no repository method to mint one. Not
/// cryptographically anything — collision within one test run is what
/// matters, and a counter is sufficient for that.
abstract final class FakeIds {
  static final _counters = <String, int>{};

  static String next(String prefix) {
    final n = (_counters[prefix] ?? 0) + 1;
    _counters[prefix] = n;
    return '${prefix}_abuse_$n';
  }
}
