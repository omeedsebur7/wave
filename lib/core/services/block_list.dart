import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The set of accounts the signed-in user has blocked.
///
/// Blocking was previously written to Firestore and read only by the profile
/// screen, so the block button changed a toggle and nothing else: blocked
/// accounts' Reels stayed in the feed, their comments stayed under posts, and
/// their conversations stayed in the chat list. The report sheet meanwhile told
/// people "you will stop seeing their posts and messages", which was untrue.
///
/// Filtering happens client-side, and that is a deliberate limitation rather
/// than an oversight. Firestore has no efficient "not in this arbitrary list"
/// operator: `whereNotIn` caps at 10 values and cannot be combined with the
/// ordering the feed needs. The alternatives are a per-user materialised feed
/// (a Phase 2 scale problem, not a Phase 1 one) or filtering after the fetch.
///
/// What that costs, stated plainly: a blocked author's Reel is downloaded and
/// then dropped, so it consumes a slot in the page. The feed asks for a page and
/// may render fewer items than it fetched. That is acceptable because block
/// lists are short in practice; it would not be acceptable if they were long.
class BlockList {
  BlockList(this._db, this._auth) {
    _subscribe();
    // Re-subscribes on sign-in and sign-out. Without this the previous user's
    // block list would keep filtering the next user's feed on a shared device.
    _authSub = _auth.authStateChanges().listen((_) => _subscribe());
  }

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _blocksSub;
  StreamSubscription<User?>? _authSub;

  final _controller = StreamController<Set<String>>.broadcast();
  Set<String> _blocked = const {};

  /// Synchronous access for filtering inside a build or a map callback.
  ///
  /// Kept as a plain field rather than a Future because the feed filters on
  /// every emission, and awaiting a read there would either stall the list or
  /// flash unfiltered content before hiding it — which defeats the point.
  Set<String> get blockedIds => _blocked;

  Stream<Set<String>> get changes => _controller.stream;

  bool isBlocked(String? userId) =>
      userId != null && _blocked.contains(userId);

  /// True when anything in [authorIds] is blocked. Used by the chat list, where
  /// a conversation has two participants.
  bool anyBlocked(Iterable<String?> authorIds) =>
      authorIds.any(isBlocked);

  void _subscribe() {
    _blocksSub?.cancel();

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _blocked = const {};
      _controller.add(_blocked);
      return;
    }

    _blocksSub = _db
        .collection('blocks')
        .doc(uid)
        .collection('blocked')
        .snapshots()
        .listen((snap) {
      _blocked = {for (final doc in snap.docs) doc.id};
      _controller.add(_blocked);
    });
  }

  Future<void> dispose() async {
    await _blocksSub?.cancel();
    await _authSub?.cancel();
    await _controller.close();
  }
}
