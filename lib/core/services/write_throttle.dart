import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// FIXED: Hidden raw ints
const int _durComment = 5;
const int _durFollow = 2;
const int _durReport = 30;

enum ThrottledWrite {
  comment('last_comment_at', Duration(seconds: _durComment)), // FIXED
  follow('last_follow_at', Duration(seconds: _durFollow)), // FIXED
  report('last_report_at', Duration(seconds: _durReport)); // FIXED

  const ThrottledWrite(this.field, this.cooldown);

  final String field;
  final Duration cooldown;
}

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
