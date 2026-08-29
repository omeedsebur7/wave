import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/seed.dart';
import 'helpers/test_bootstrap.dart';

/// Security abuse test, round 3: RATE-LIMIT BACKDATING.
///
/// firestore.rules' `rate_limits/{userId}` block, in full:
///
///   allow read: if isSelf(userId);
///   allow create: if isSelf(userId);
///   allow update: if isSelf(userId)
///     && request.resource.data.keys().hasOnly([
///          'last_comment_at', 'last_follow_at', 'last_report_at'])
///     && (!('last_comment_at' in request.resource.data)
///          || request.resource.data.last_comment_at == request.time)
///     && (!('last_follow_at' in request.resource.data)
///          || request.resource.data.last_follow_at == request.time)
///     && (!('last_report_at' in request.resource.data)
///          || request.resource.data.last_report_at == request.time);
///   allow delete: if false;
///
/// `cooledDown(field, seconds)` reads this document and computes
/// `request.time - stored[field] > seconds * 1000` — so the ONLY way to pass
/// a cooldown early is to make the stored timestamp read as further in the
/// past than it really is. The update rule blocks that directly: an updated
/// timestamp must equal request.time exactly, which for a FieldValue.
/// serverTimestamp() sentinel resolves server-side to the real moment of the
/// write — a client literally cannot supply any OTHER value on update and
/// have it accepted.
///
/// THE GAP WORTH TESTING: `allow create` carries none of those constraints.
/// It only checks isSelf(userId) — no keys().hasOnly(), no equality-to-
/// request.time. If this document does not exist yet, a client can `set()`
/// it with ANY fields and ANY values, including a `last_report_at` dated
/// years in the past, and cooledDown() would then read that account as
/// perpetually cooled down for reports from the very first check onward.
///
/// This is the one test in this file testing something I could not confirm
/// from any function source — only from the rule text itself, which I did
/// read in full. If the rule you are running differs from what is quoted
/// above, re-derive this test from the actual text rather than trusting this
/// comment.
///
/// AFTER THE FIX WAS APPLIED: `allow create` now carries the same
/// keys().hasOnly() and (field == request.time) constraints `allow update`
/// always had. That closes the gap this file found — but it also means every
/// LEGITIMATE setup write in this file that used a client-clock
/// `Timestamp.now()` broke, because create no longer accepts an arbitrary
/// timestamp even from a genuine first write. Every setup step below now uses
/// `FieldValue.serverTimestamp()`, which is what a real client actually
/// sends; `Timestamp.fromDate(...)` remains ONLY in the lines that are
/// deliberately attempting the attack, where being refused is the point.
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

  group('Cross-user tampering', () {
    testWidgets(
      "a user cannot write to someone else's rate_limits document",
      (tester) async {
        final victim = await seed.seedSeller();
        await seed.signInAsSeller();

        await expectLater(
          seed.clientSet(
            'rate_limits/$victim',
            data: {'last_report_at': Timestamp.now()},
          ),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
          reason: 'isSelf(userId) must hold on create too — otherwise an '
              "attacker could freeze or unfreeze a stranger's cooldowns at "
              'will, including making the VICTIM unable to file reports by '
              'pinning their timestamp to "just now" forever',
        );
      },
    );

    testWidgets(
      "a user cannot UPDATE someone else's rate_limits document either",
      (tester) async {
        final victim = await seed.seedSeller();
        // Seed the victim's own document as themselves, so the update below
        // is a genuine update, not a create — the two paths have different
        // rules and both need covering.
        //
        // FieldValue.serverTimestamp(), not Timestamp.now(). Create now
        // carries the same == request.time constraint update always had —
        // that is the fix this file's own findings produced — so a
        // client-clock Timestamp.now() no longer satisfies even a
        // LEGITIMATE first write. Using the sentinel here is not a workaround
        // for the rule; it is what a real client write actually looks like.
        await seed.clientSet(
          'rate_limits/$victim',
          data: {'last_report_at': FieldValue.serverTimestamp()},
        );

        await seed.signInAsSeller();

        await expectLater(
          seed.clientUpdate(
            'rate_limits/$victim',
            {'last_report_at': Timestamp.now()},
          ),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
        );
      },
    );
  });

  group('Backdating via update — should be closed', () {
    testWidgets(
      'an updated cooldown timestamp cannot be set to a past moment',
      (tester) async {
        final uid = await seed.signInAsSeller();

        // A genuine document has to exist first. FieldValue.serverTimestamp(),
        // not Timestamp.now() — create now requires the same == request.time
        // equality update always did, so this setup step must look like a
        // real write, not merely a permitted one.
        await seed.clientSet(
          'rate_limits/$uid',
          data: {'last_report_at': FieldValue.serverTimestamp()},
        );

        final farInThePast = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 365)),
        );

        await expectLater(
          seed.clientUpdate('rate_limits/$uid', {
            'last_report_at': farInThePast,
          }),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
          reason: 'the update rule requires the new value to equal '
              'request.time exactly — an arbitrary Timestamp, even one '
              'wrapped to look like a legitimate write, must be refused. '
              'This is the check that makes the CREATE gap below actually '
              'matter: if update also allowed this, backdating would need '
              'no first-write trick at all',
        );
      },
    );

    testWidgets(
      'an update cannot smuggle an out-of-scope field alongside legal ones',
      (tester) async {
        final uid = await seed.signInAsSeller();
        await seed.clientSet(
          'rate_limits/$uid',
          data: {'last_comment_at': FieldValue.serverTimestamp()},
        );

        await expectLater(
          seed.clientUpdate('rate_limits/$uid', {
            'last_comment_at': FieldValue.serverTimestamp(),
            'phone_verified': true, // not a rate_limits field at all
          }),
          throwsA(predicate((e) => '$e'.contains('permission-denied'))),
          reason: 'hasOnly() must refuse the whole write the moment an '
              'unlisted key rides along — the same shape of check that has '
              'a regression guard on orders.has_been_rated in '
              'identity_spoofing_test.dart',
        );
      },
    );
  });

  group(
    'Backdating via first-write CREATE — THE GAP',
    () {
      // If this group's tests come back GREEN — the writes below are
      // ACCEPTED rather than refused — that is the finding. It means:
      //
      //   1. A brand-new account can pre-poison its own rate_limits document
      //      with a last_report_at years in the past, then file reports at
      //      any rate forever, because cooledDown() will always compute a
      //      gap larger than the cooldown window.
      //   2. The same applies to last_comment_at and last_follow_at — comment
      //      spam and follow-spam both lose their per-user throttle the same
      //      way.
      //
      // The fix, if this is confirmed: give `allow create` the same
      // constraints as `allow update` — hasOnly() plus the == request.time
      // check on whichever field is present — since Firestore rules do not
      // share constraints between create and update automatically.

      testWidgets(
        'a fresh account can set last_report_at to a fabricated past date',
        (tester) async {
          final uid = await seed.signInAsSeller();
          // No prior rate_limits/$uid document exists — clearAll() in setUp
          // guarantees this is a genuine first write, i.e. a CREATE.

          final farInThePast = Timestamp.fromDate(
            DateTime(2000),
          );

          // Deliberately NOT wrapped in expectLater(throwsA(...)) — the
          // point of this group is to observe which outcome actually
          // happens, and assert on THAT, rather than assume the answer.
          var wasAccepted = false;
          try {
            await seed.clientSet(
              'rate_limits/$uid',
              data: {'last_report_at': farInThePast},
            );
            wasAccepted = true;
          } catch (_) {
            wasAccepted = false;
          }

          expect(
            wasAccepted,
            isFalse,
            reason: wasAccepted
                ? 'CONFIRMED GAP: rate_limits create accepted an arbitrary '
                    'past timestamp for last_report_at. A fresh account can '
                    'file reports at an unthrottled rate indefinitely. Add '
                    'the same hasOnly() + (field == request.time) '
                    'constraints to `allow create` that `allow update` '
                    'already has.'
                : 'create was correctly refused — either the rule already '
                    "guards create, or this test's assumptions about the "
                    'rule text are stale; worth confirming against the '
                    'actual firestore.rules either way',
          );
        },
      );

      testWidgets(
        'a fresh account can set last_comment_at to a fabricated past date',
        (tester) async {
          final uid = await seed.signInAsSeller();
          final farInThePast = Timestamp.fromDate(DateTime(2000));

          var wasAccepted = false;
          try {
            await seed.clientSet(
              'rate_limits/$uid',
              data: {'last_comment_at': farInThePast},
            );
            wasAccepted = true;
          } catch (_) {
            wasAccepted = false;
          }

          expect(
            wasAccepted,
            isFalse,
            reason: wasAccepted
                ? 'CONFIRMED GAP: same issue as last_report_at, on comment '
                    'throttling — a fresh account can comment at an '
                    'unthrottled rate indefinitely.'
                : 'create was correctly refused for this field',
          );
        },
      );

      testWidgets(
        'a fresh account can set last_follow_at to a fabricated past date',
        (tester) async {
          final uid = await seed.signInAsSeller();
          final farInThePast = Timestamp.fromDate(DateTime(2000));

          var wasAccepted = false;
          try {
            await seed.clientSet(
              'rate_limits/$uid',
              data: {'last_follow_at': farInThePast},
            );
            wasAccepted = true;
          } catch (_) {
            wasAccepted = false;
          }

          expect(
            wasAccepted,
            isFalse,
            reason: wasAccepted
                ? 'CONFIRMED GAP: same issue as last_report_at, on follow '
                    'throttling.'
                : 'create was correctly refused for this field',
          );
        },
      );

      testWidgets(
        'create with an out-of-scope field is at least worth knowing about',
        (tester) async {
          final uid = await seed.signInAsSeller();

          // Not necessarily exploitable on its own — rate_limits has no
          // fields outside the three cooldown timestamps that anything reads
          // — but confirms whether `allow create` restricts SHAPE at all, or
          // only identity. If this is accepted, the document's shape is
          // entirely client-controlled on first write.
          var wasAccepted = false;
          try {
            await seed.clientSet(
              'rate_limits/$uid',
              data: {'anything_at_all': 'not a real field'},
            );
            wasAccepted = true;
          } catch (_) {
            wasAccepted = false;
          }

          // Informational rather than a hard pass/fail on its own — logged
          // via reason regardless of outcome, since either answer is useful
          // context for triaging the three tests above.
          // ignore: avoid_print
          print(
            wasAccepted
                ? 'INFO: rate_limits create accepts arbitrary field names — '
                    'confirms the create rule checks identity only, not shape.'
                : 'INFO: rate_limits create rejected an unrecognised field — '
                    'the create rule may already constrain shape somehow; '
                    'worth reconciling with what the tests above found.',
          );
        },
      );
    },
  );
}
