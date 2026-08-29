import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/services/write_throttle.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';

/// Both sides of the report flow (§4).
///
/// The brief asks for a report button *paired with a basic admin review queue*.
/// A report button without a queue is worse than no button: the confirmation
/// screen tells the reporter a moderator will look at it, and no moderator can.
///
/// Moderator access is gated on a custom claim rather than a Firestore flag,
/// because a claim travels in the token and Security Rules can check it without
/// a read. Set it with the Admin SDK:
///
///     admin.auth().setCustomUserClaims(uid, { moderator: true })
class ModerationRepository {
  ModerationRepository(this._db, this._auth, this._functions, this._throttle);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final WriteThrottle _throttle;

  /// Files a report.
  ///
  /// This is the write the confirmation screen promises. Without it the queue
  /// stays permanently empty while the app assures every reporter that someone
  /// will look.
  Future<Result<void>> fileReport({
    required ReportTargetType targetType,
    required String targetId,
    required ReportReason reason,
    bool alsoBlock = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Err(
        AuthFailure('Sign in to report', reason: FailureReason.signInToReport),
      );
    }

    // Report-bombing a competitor is a real marketplace tactic, and the dedupe
    // trigger only collapses reports on the SAME target — it does nothing about
    // one account reporting fifty different listings.
    final wait = await _throttle.remaining(ThrottledWrite.report);
    if (wait != null) {
      return Err(RateLimitedFailure(
        'Report write throttled',
        retryAfter: wait,
        reason: FailureReason.reportThrottled,
      ),);
    }

    try {
      await _throttle.stamp(ThrottledWrite.report);

      await _db.collection('reports').add({
        'target_type': targetType.name,
        'target_id': targetId,
        'reason': reason.name,
        'reporter_id': uid,
        // Written by the client so the queue can filter on it. Security Rules
        // pin it to 'pending' on create; only the dedupe trigger and
        // resolveReport may change it afterwards.
        'action': ModerationAction.pending.name,
        'report_count': 1,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (alsoBlock && targetType != ReportTargetType.product) {
        final ownerId = await _ownerOf(targetType, targetId);
        if (ownerId != null && ownerId != uid) {
          await _db
              .collection('blocks')
              .doc(uid)
              .collection('blocked')
              .doc(ownerId)
              .set({'created_at': FieldValue.serverTimestamp()});
        }
      }

      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Could not send the report',
          code: e.code,
          reason: FailureReason.reportFailed,
        ),
      );
    }
  }

  /// Whether the signed-in user can see the queue at all.
  ///
  /// Read from the token, not from a document — a client able to grant itself
  /// a Firestore flag could read every report in the system.
  Future<bool> isModerator() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult();
    return token.claims?['moderator'] == true;
  }

  /// Urgent first, then most-reported, then oldest.
  ///
  /// Oldest rather than newest, deliberately: a queue that surfaces the newest
  /// report first leaves the bottom permanently unreviewed once volume exceeds
  /// capacity — which is exactly when review matters most.
  Stream<List<Report>> watchQueue({int limit = 100}) {
    return _db
        .collection('reports')
        .where('action', isEqualTo: ModerationAction.pending.name)
        .orderBy('created_at')
        .limit(limit)
        .snapshots()
        .map((snap) {
      final reports = [for (final d in snap.docs) _toReport(d)];
      // Cascaded rather than `reports.sort(...); return reports;` — List.sort
      // mutates in place and returns void, so the two statements were both
      // calls on `reports` in immediate succession purely to discard sort's
      // (nonexistent) return value before handing the same list back.
      return reports
        ..sort((a, b) {
          if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
          if (a.reportCount != b.reportCount) {
            return b.reportCount.compareTo(a.reportCount);
          }
          return a.createdAt.compareTo(b.createdAt);
        });
    });
  }

  /// Records a decision and applies its consequence.
  ///
  /// Routed through a Cloud Function rather than a direct write: removing
  /// content and suspending accounts need Admin-SDK privileges the client must
  /// never hold, and the decision must land in the same batch as the action it
  /// authorises.
  Future<Result<void>> resolve({
    required String reportId,
    required ModerationAction action,
    String? note,
  }) async {
    const undecided = {ModerationAction.pending, ModerationAction.merged};
    if (undecided.contains(action)) {
      return const Err(
        ServerFailure(
          'Choose an outcome',
          reason: FailureReason.chooseAnOutcome,
        ),
      );
    }

    try {
      await _functions.httpsCallable('resolveReport').call<void>({
        'reportId': reportId,
        'action': action.name,
        if (note != null) 'note': note,
      });
      return const Success(null);
    } on FirebaseFunctionsException catch (e) {
      return Err(
        switch (e.code) {
          'permission-denied' =>
            const PermissionFailure(
              'You are not a moderator',
              FailureReason.notAModerator,
            ),
          'aborted' => const ServerFailure(
              'Another moderator reviewed this first. Refresh the queue.',
              reason: FailureReason.reportAlreadyReviewed,
            ),
          _ => ServerFailure(
              e.message ?? 'Could not record the decision',
              code: e.code,
              reason: FailureReason.decisionFailed,
            ),
        },
      );
    }
  }

  /// Resolves who owns the reported thing, so "also block" blocks a person
  /// rather than a piece of content.
  Future<String?> _ownerOf(ReportTargetType type, String id) async {
    switch (type) {
      case ReportTargetType.profile:
        return id;
      case ReportTargetType.reel:
        return (await _db.collection('reels').doc(id).get())
            .data()?['author_id'] as String?;
      case ReportTargetType.product:
        return (await _db.collection('products').doc(id).get())
            .data()?['seller_id'] as String?;
      case ReportTargetType.comment:
      case ReportTargetType.message:
        // Both live in subcollections whose parent the sheet does not carry.
        // Blocking from these entry points goes through the profile instead of
        // guessing at a path.
        return null;
    }
  }

  static Report _toReport(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Report(
      id: doc.id,
      targetType: ReportTargetType.values.firstWhere(
        (t) => t.name == d['target_type'],
        orElse: () => ReportTargetType.reel,
      ),
      targetId: d['target_id'] as String? ?? '',
      reason: ReportReason.values.firstWhere(
        (r) => r.name == d['reason'],
        orElse: () => ReportReason.other,
      ),
      reporterId: d['reporter_id'] as String? ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      action: ModerationAction.values.firstWhere(
        (a) => a.name == d['action'],
        orElse: () => ModerationAction.pending,
      ),
      reviewedBy: d['reviewed_by'] as String?,
      reviewedAt: (d['reviewed_at'] as Timestamp?)?.toDate(),
      note: d['note'] as String?,
      reportCount: (d['report_count'] as num?)?.toInt() ?? 1,
    );
  }
}
