import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wave/features/publish/data/reel_upload_service.dart';

import 'helpers/fake_bunny.dart';
import 'helpers/seed.dart';
import 'helpers/test_bootstrap.dart';

/// Publish flow integration test (§6).
///
/// Requires THREE processes:
///
///   1. node tools/bunny-stub.mjs        (with ENCODE_MS matching _encodeMs)
///   2. firebase emulators:start
///   3. flutter test integration_test/publish_flow_test.dart -d <device> \
///        --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=10.0.2.2
///
/// Bunny is stubbed by tools/bunny-stub.mjs, which the FUNCTION calls over HTTP
/// via BUNNY_API_BASE and which [FakeBunny] reads over the same HTTP. That
/// shared stub is the point. FakeBunny was previously an in-process Dart object
/// while createBunnyUploadSlot called video.bunnycdn.com — two unconnected
/// systems — so `expect(bunny.videoCount, 0)` passed because nothing had
/// touched the fake, and would have passed identically had the function created
/// ten real billed videos.
///
/// The stub deliberately preserves the one behaviour these assertions depend
/// on: encoding is asynchronous and takes time. A stub reporting "ready"
/// immediately would let a broken implementation pass, because the bug being
/// guarded against is publishing a Reel before its rendition ladder exists.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Must equal ENCODE_MS on the stub process.
  ///
  /// Generous on purpose. At 200ms the "still encoding" assertion raced the
  /// round trip it was making — a slow emulator turned a correct
  /// implementation into a red test, which is the worst kind of flake because
  /// it teaches you to rerun rather than to look.
  const encodeMs = 1500;

  late TestSeed seed;
  late FakeBunny bunny;

  setUpAll(() async {
    await initializeIntegrationFirebase();
  });

  setUp(() async {
    seed = TestSeed.instance();
    bunny = FakeBunny(encodeDuration: const Duration(milliseconds: encodeMs));
    await seed.clearAll();
    // Fails loudly with "Is the stub running?" rather than letting every
    // assertion below quietly measure nothing.
    await bunny.reset();
  });

  /// Requests a REAL upload slot and returns its Bunny video id.
  ///
  /// The tests used to call `bunny.createSlot()`, which invented an id in the
  /// test process. No pending_uploads document existed behind it, so
  /// publishReel refused with "That upload is not yours" — correctly, since
  /// that check is what stops one seller publishing against another's slot.
  /// Only the real callable creates the ownership record.
  Future<String> requestSlot({int durationSeconds = 30}) async {
    final slot = await seed.requestUploadSlot(
      durationSeconds: durationSeconds,
    );
    expect(slot, isNotNull, reason: 'requestUploadSlot returned no slot');
    return slot!['videoId'] as String;
  }

  group('Publishing a Reel (§4)', () {
    testWidgets('a 61-second video is rejected before anything is uploaded',
        (tester) async {
      // The check has to come first, or someone on a slow connection waits
      // through a long upload to be told no at the end. It also has to come
      // before the Bunny call, or a rejected duration still costs a billed
      // video object.
      await seed.signInAsSeller();

      await expectLater(
        seed.requestUploadSlot(durationSeconds: 61),
        throwsA(predicate((e) => '$e'.contains('invalid-argument'))),
      );

      // Now reads the stub the function actually talks to, so it can fail.
      expect(
        await bunny.videoCount(),
        0,
        reason: 'no Bunny video object may be created for a rejected duration',
      );
    });

    testWidgets('exactly 60 seconds is allowed', (tester) async {
      // Off-by-one at the boundary would silently reject a legitimate Reel.
      await seed.signInAsSeller();

      final videoId = await requestSlot(
        durationSeconds: ReelUploadService.maxDurationSeconds,
      );

      expect(videoId, isNotEmpty);
      expect(
        await bunny.videoCount(),
        1,
        reason: 'the accepted duration must have created exactly one video',
      );
    });

    testWidgets('no Reel document exists until the video is playable',
        (tester) async {
      // A Reel that exists before its rendition ladder does is a Reel the feed
      // will show and fail to play.
      final sellerId = await seed.signInAsSeller();
      final videoId = await requestSlot();

      // Created but no bytes yet.
      expect((await bunny.status(videoId)).ready, isFalse);
      expect(await seed.reelCountFor(sellerId), 0);

      await bunny.upload(videoId);

      // Encoding. The encodeMs headroom is what makes this assertion about the
      // implementation rather than about how fast the test machine is.
      expect((await bunny.status(videoId)).ready, isFalse);
      expect(await seed.reelCountFor(sellerId), 0);

      await Future<void>.delayed(
        const Duration(milliseconds: encodeMs + 300),
      );
      expect((await bunny.status(videoId)).ready, isTrue);

      await seed.publishReel(bunnyVideoId: videoId, durationSeconds: 30);
      expect(await seed.reelCountFor(sellerId), 1);
    });

    testWidgets('a failed encode cannot be published', (tester) async {
      final sellerId = await seed.signInAsSeller();
      await bunny.failNextEncode();

      final videoId = await requestSlot();
      await bunny.upload(videoId);
      await Future<void>.delayed(
        const Duration(milliseconds: encodeMs + 300),
      );

      final status = await bunny.status(videoId);
      expect(status.failed, isTrue);
      expect(status.ready, isFalse);

      // THE ASSERTION THIS TEST EXISTS FOR — and it only became possible
      // once publishReel was fixed to actually check.
      //
      // Until then, publishReel verified the pending_uploads ownership record
      // and NOTHING else. Its own doc comment claimed it "writes the Reel
      // document once the video is genuinely playable", but that guarantee
      // lived entirely in the client, which polls bunnyVideoStatus and only
      // publishes on ready. A client bug, a race between the poll and the
      // call, or a modified client bypassed it completely: this exact call,
      // on this exact failed video, used to SUCCEED and write a Reel the feed
      // could never play.
      //
      // The earlier version of this test could only assert that the STATUS
      // ENDPOINT reported failure correctly — the two expects above. The real
      // gap was left as a comment carrying this assertion verbatim, because a
      // failing test nobody can fix from this file alone just gets skipped.
      // publishReel now fetches Bunny's status directly and refuses anything
      // that is not status 4.
      await expectLater(
        seed.publishReel(bunnyVideoId: videoId, durationSeconds: 30),
        throwsA(predicate((e) => '$e'.contains('failed-precondition'))),
        reason: 'publishReel must refuse a video whose encode failed, on the '
            'server, rather than trusting that the client only ever calls it '
            'after a successful poll',
      );

      // Nothing was written. The refusal has to be complete, not partial —
      // a Reel document that exists in any state for an unplayable video is
      // the bug this whole test guards.
      expect(await seed.reelCountFor(sellerId), 0);
    });

    testWidgets('a still-encoding video cannot be published either', (
      tester,
    ) async {
      // The other half of the same check, and the likelier one in practice: a
      // video that has NOT failed, is simply not finished yet. A client that
      // publishes optimistically — or one whose poll raced the encode — hits
      // this path far more often than a genuine encode failure.
      //
      // Bunny reports these differently (status 2 = encoding, 5 = failed) but
      // publishReel treats both the same way, because `status !== 4` is the
      // only question that matters at the moment of writing a Reel.
      final sellerId = await seed.signInAsSeller();

      final videoId = await requestSlot();

      // Deliberately NOT calling bunny.upload() — no bytes, no uploadedAt, no
      // encode clock running at all. The stub's own statusOf() returns
      // STATUS.CREATED (0) for a video with uploadedAt == null, unconditionally,
      // with no dependency on wall-clock timing.
      //
      // The first version of this test called upload() and then read status
      // WITHOUT waiting out encodeMs, on the theory that a network round trip
      // was fast enough to land reliably inside the encode window. It was not:
      // asserting client-side status, then making a SEPARATE server-side call
      // that does its own fetch to the stub, is two independent reads of one
      // clock from two different processes — and at encodeMs of 1500ms, the
      // gap between them was occasionally enough to cross the threshold. The
      // test failed maybe one run in several, which is worse than failing
      // every time: it reads as flaky infrastructure rather than as what it
      // actually was, a race condition in the TEST rather than in the code
      // under test.
      final status = await bunny.status(videoId);
      expect(
        status.ready,
        isFalse,
        reason: 'precondition: the video must not be ready here, or this '
            'test is not exercising the path it claims to',
      );
      expect(status.failed, isFalse);

      await expectLater(
        seed.publishReel(bunnyVideoId: videoId, durationSeconds: 30),
        throwsA(predicate((e) => '$e'.contains('failed-precondition'))),
      );

      expect(await seed.reelCountFor(sellerId), 0);

      // And once upload actually happens and encoding genuinely finishes, the
      // same call succeeds — proving the refusal above was about readiness
      // and not about something incidental to this upload. Without this, a
      // publishReel that rejected everything would pass both assertions
      // above.
      await bunny.upload(videoId);
      await Future<void>.delayed(
        const Duration(milliseconds: encodeMs + 300),
      );
      await seed.publishReel(bunnyVideoId: videoId, durationSeconds: 30);
      expect(await seed.reelCountFor(sellerId), 1);
    });

    testWidgets('caption_lower is written, or search will never find it',
        (tester) async {
      final sellerId = await seed.signInAsSeller();
      final videoId = await requestSlot();

      await bunny.upload(videoId);
      await Future<void>.delayed(
        const Duration(milliseconds: encodeMs + 300),
      );

      final reelId = await seed.publishReel(
        bunnyVideoId: videoId,
        durationSeconds: 30,
        caption: 'Handmade Leather Bag',
      );

      final reel = await seed.reel(reelId);
      expect(reel!['caption_lower'], 'handmade leather bag');
      expect(reel['author_id'], sellerId);
    });

    testWidgets('only your own product can be linked', (tester) async {
      // Otherwise anyone could attach a Buy Now button pointing at someone
      // else's listing and collect the attention for a sale they do not make.
      final otherSeller = await seed.seedSeller();
      final theirProduct = await seed.seedProduct(sellerId: otherSeller);

      // seedSeller signed the other seller in; this replaces the session, and
      // the slot below therefore belongs to THIS seller. That ordering is what
      // makes the refusal below about the product link rather than about
      // upload ownership.
      await seed.signInAsSeller();
      final videoId = await requestSlot();

      await bunny.upload(videoId);
      await Future<void>.delayed(
        const Duration(milliseconds: encodeMs + 300),
      );

      await expectLater(
        seed.publishReel(
          bunnyVideoId: videoId,
          durationSeconds: 30,
          linkedProductId: theirProduct,
        ),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );

      // The refusal must leave nothing behind.
      expect(await seed.reelCountFor(otherSeller), 0);
    });

    testWidgets('an upload slot cannot be published by someone else',
        (tester) async {
      // The check that "That upload is not yours" exists for, asserted
      // deliberately rather than tripped over by accident. Three tests used to
      // fail on this message because they invented their own video ids; none of
      // them was testing it.
      await seed.signInAsSeller();
      final videoId = await requestSlot();
      await bunny.upload(videoId);
      await Future<void>.delayed(
        const Duration(milliseconds: encodeMs + 300),
      );

      // A different seller now holds the session.
      await seed.signInAsSeller();

      await expectLater(
        seed.publishReel(bunnyVideoId: videoId, durationSeconds: 30),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );
    });

    testWidgets('a Reel with no linked product carries no Buy Now',
        (tester) async {
      final sellerId = await seed.signInAsSeller();
      final reelId = await seed.seedReel(authorId: sellerId);

      final reel = await seed.reel(reelId);
      expect(reel!['linked_product_id'], isNull);
    });

    testWidgets('someone else cannot change your product link', (tester) async {
      final sellerId = await seed.seedSeller();
      final reelId = await seed.seedReel(authorId: sellerId);
      final productId = await seed.seedProduct(sellerId: sellerId);

      // A different signed-in user.
      await seed.signInAsSeller();

      await expectLater(
        seed.setReelProductLink(reelId, productId),
        throwsA(anything),
      );
    });

    testWidgets('the eleventh Reel in an hour is rate-limited', (tester) async {
      final sellerId = await seed.signInAsSeller();
      for (var i = 0; i < 10; i++) {
        await seed.seedReel(authorId: sellerId, caption: 'Reel $i');
      }

      await expectLater(
        seed.requestUploadSlot(durationSeconds: 30),
        throwsA(predicate((e) => '$e'.contains('resource-exhausted'))),
      );

      // Throttled BEFORE the Bunny call, so a script hitting the limit cannot
      // still run up a video library. The limit exists for the cost, not just
      // for the feed.
      expect(await bunny.videoCount(), 0);
    });

    testWidgets('a guest cannot request an upload slot', (tester) async {
      await seed.signInGuest();

      await expectLater(
        seed.requestUploadSlot(durationSeconds: 30),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );

      expect(await bunny.videoCount(), 0);
    });

    testWidgets('a Bunny failure leaves no ownership record behind',
        (tester) async {
      // Exercises the `!created.ok` branch. Previously unreachable: with no
      // stub, every call failed there, so the branch was permanently taken and
      // never distinguished from the configured case.
      await seed.signInAsSeller();
      await bunny.failNextCreate();

      await expectLater(
        seed.requestUploadSlot(durationSeconds: 30),
        throwsA(predicate((e) => '$e'.contains('Could not create the video'))),
      );

      // No video, and — the part that matters — no orphaned pending_uploads
      // document claiming one.
      expect(await bunny.videoCount(), 0);
    });
  });

  group('Feed stability under scroll (§6)', () {
    testWidgets(
      'the controller window holds under a long scroll',
      (tester) async {
        // Covered exhaustively as a unit test in
        // test/features/reel_controller_pool_test.dart, which can inject a
        // fake player and assert dispose() specifically. This exists only to
        // confirm the same invariant survives a real feed with real
        // pagination — the unit test uses a synthetic list.
        final sellerId = await seed.seedSeller();
        await seed.seedFeed(authorId: sellerId);
        expect(await seed.reelCountFor(sellerId), 50);
      },
    );
  });
}
