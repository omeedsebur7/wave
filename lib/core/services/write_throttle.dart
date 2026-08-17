import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Which server-side cooldown a write is subject to.
enum ThrottledWrite {
  comment('last_comment_at', Duration(seconds: 5)),
  follow('last_follow_at', Duration(seconds: 2)),
  report('last_report_at', Duration(seconds: 30));

  const ThrottledWrite(this.field, this.cooldown);

  final String field;

  /// Mirrors the value in `firestore.rules`. Duplicated on purpose: the rule is
  /// the enforcement, this is only so the UI can say how long to wait instead
  /// of showing a bare permission error.
  final Duration cooldown;
}

/// Stamps the per-user throttle document that Security Rules check (§4).
///
/// The rules require `request.time` exactly, so the timestamp cannot be forged
/// or rewound — a client that could write its own value could clear its own
/// cooldown. That means this must be a separate write rather than part of the
/// batch: `serverTimestamp()` inside a batch resolves to the commit time, which
/// the rule cannot compare against `request.time`.
///
/// Stamped BEFORE the throttled write. If the throttled write then fails the
/// user has spent a cooldown on nothing, which is a small unfairness; stamping
/// afterwards would let a client skip the stamp entirely and never be limited.
class WriteThrottle {
  WriteThrottle(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> stamp(ThrottledWrite write) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.collection('rate_limits').doc(uid).set(
      {write.field: FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// How long until this kind of write is allowed again, or null if it is
  /// allowed now.
  ///
  /// Read from the same document the rules read, so the UI and the enforcement
  /// cannot disagree about whose clock is right.
  Future<Duration?> remaining(ThrottledWrite write) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('rate_limits').doc(uid).get();
    final last = (doc.data()?[write.field] as Timestamp?)?.toDate();
    if (last == null) return null;

    final elapsed = DateTime.now().difference(last);
    final left = write.cooldown - elapsed;
    return left.isNegative ? null : left;
  }
}
