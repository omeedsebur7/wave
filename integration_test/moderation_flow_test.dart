import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/seed.dart';
import 'helpers/test_bootstrap.dart';

/// Moderation integration test.
///
/// Run against the Firebase emulator suite, never production:
///
///     firebase emulators:start
///     flutter test integration_test/moderation_flow_test.dart -d <device> \
///       --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=10.0.2.2
///
/// A note on identities, because getting it wrong reads as a rules bug:
///
/// `reports` and `moderation_log` are both readable only by a moderator, and
/// TestSeed's own session is a plain buyer or seller by design — it seeds
/// through the app's real rules rather than an Admin SDK bypass. So every read
/// of a report or an audit entry goes through a SecondModerator, which holds
/// the claim. TestSeed.getReport used to exist and was refused by exactly the
/// rule that stops ordinary users browsing other people's reports.
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

  group('Two moderators cannot both resolve the same report', () {
    // resolveReport used to read a report's status, decide the whole
    // function's behaviour from it, and only write roughly eighty lines
    // later — through an unconditional WriteBatch with no re-check. A comment
    // beside the original read said the double-resolution race was "worth
    // losing loudly", which shows the author had identified the danger and
    // had not actually closed it: a batch commits unconditionally, so two
    // moderators within that window would both pass the pending check and
    // both proceed.
    //
    // The append-only audit log made this worse than a silent overwrite: it
    // allocates a new document per call rather than reusing one, so a lost
    // race would still produce a log entry for the decision that did NOT
    // stick — an audit trail actively misrepresenting which action took
    // effect, which is worse than no audit trail, because it looks
    // authoritative.

    testWidgets(
      'exactly one resolution succeeds when two moderators race',
      (tester) async {
        final sellerId = await seed.seedSeller();
        final reelId = await seed.seedReel(authorId: sellerId);
        final reportId = await seed.seedReport(targetId: reelId);

        final modA = await TestSeed.signInSecondModerator();
        final modB = await TestSeed.signInSecondModerator();

        // Fired together, not sequentially — see the identical reasoning in
        // purchase_flow_test.dart's concurrent-purchase test. Two sequential
        // calls would let the first transaction fully commit before the
        // second even started reading, proving a lock rather than a race.
        final results = await Future.wait([
          modA
              .resolveReport(reportId: reportId, action: 'dismissed')
              .catchError((Object e) => <String, dynamic>{'error': '$e'}),
          modB
              .resolveReport(reportId: reportId, action: 'contentRemoved')
              .catchError((Object e) => <String, dynamic>{'error': '$e'}),
        ]);

        final succeeded =
            results.where((r) => r != null && !r.containsKey('error'));
        final failed =
            results.where((r) => r == null || r.containsKey('error'));

        // Exactly one moderator's decision must win — not zero, and not both
        // silently taking effect with the log showing whichever one it feels
        // like.
        expect(
          succeeded.length,
          1,
          reason: 'exactly one moderator must resolve the report, not '
              'both and not neither',
        );
        expect(failed.length, 1);

        // The loser must see the actual reason — someone else already acted —
        // not a generic failure that would make a lost race look like a
        // broken button.
        final loser = failed.single;
        expect(
          loser,
          isNotNull,
          reason: 'the losing call returned null rather than an error, so the '
              'reason below cannot be checked at all',
        );
        expect('${loser!['error']}', contains('Already reviewed'));

        // The report reflects exactly one of the two actions attempted, never
        // both and never neither. Checking against the report directly rather
        // than trusting the winning call's own return value, because the bug
        // this guards against is a WRITE inconsistency — the two could
        // disagree even if the calls themselves both reported success.
        //
        // Read through modA, not seed: `reports` requires the moderator claim,
        // and TestSeed's identity is a plain seller here. Either moderator
        // would do — the report is shared, not scoped to whichever decision
        // won.
        final report = await modA.report(reportId);
        expect(report, isNotNull);
        expect(['dismissed', 'contentRemoved'], contains(report!['action']));
        expect(report['action'], isNot('pending'));

        // The audit log has exactly one entry, not one per attempt. This is
        // the assertion that would have failed against the original
        // WriteBatch version even if the report-level race were somehow
        // otherwise avoided — a second, separate log document was allocated
        // per call regardless of whether the report update actually landed.
        expect(await modA.moderationLogCount(reportId), 1);

        await modA.dispose();
        await modB.dispose();
      },
    );

    testWidgets('a moderator resolving alone still works normally',
        (tester) async {
      // The rewrite touches every code path in the function, including the
      // ordinary, uncontested case. This is the test that would catch a
      // transaction-conversion mistake that broke normal use while
      // "fixing" the race — the single most likely way this kind of change
      // goes wrong.
      final sellerId = await seed.seedSeller();
      final reelId = await seed.seedReel(authorId: sellerId);
      final reportId = await seed.seedReport(targetId: reelId);

      final mod = await TestSeed.signInSecondModerator();
      final result =
          await mod.resolveReport(reportId: reportId, action: 'dismissed');

      expect(result?['ok'], true);

      final report = await mod.report(reportId);
      expect(report, isNotNull);
      expect(report!['action'], 'dismissed');
      expect(await mod.moderationLogCount(reportId), 1);

      await mod.dispose();
    });

    testWidgets('an ordinary user cannot read a report at all', (tester) async {
      // The rule that made the two tests above fail, asserted deliberately
      // rather than tripped over. TestSeed.getReport existed and was refused —
      // correctly — and the refusal read as a moderation bug for two rounds
      // because nothing said out loud that a plain user is supposed to be
      // refused here. Reports name a reporter and a target; a marketplace
      // where any seller can read who reported whom has a harassment problem,
      // not a permissions inconvenience.
      final sellerId = await seed.seedSeller();
      final reelId = await seed.seedReel(authorId: sellerId);
      final reportId = await seed.seedReport(targetId: reelId);

      // seedSeller left an ordinary, non-moderator seller signed in.
      await expectLater(
        seed.reportAsCurrentUser(reportId),
        throwsA(predicate((e) => '$e'.contains('permission-denied'))),
      );
    });
  });
}