import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:wave/core/error/failures.dart';
import 'package:wave/core/services/block_list.dart';
import 'package:wave/core/utils/rate_limiter.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/chat/domain/entities/conversation.dart';


class ChatRepository {
  ChatRepository(this._db, this._auth, this._blocks);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  /// A blocked person's conversation leaves the list.
  ///
  /// The thread itself is not deleted — the messages are shared history and the
  /// other party has their own copy. It simply stops appearing, which is what
  /// "you will stop seeing their messages" means.
  final BlockList _blocks;

  /// Anti-abuse throttle (§4). Generous enough for a real conversation, tight
  /// enough that a script can't flood an inbox.
  final _limiter =
      RateLimiter(maxEvents: 20, window: const Duration(minutes: 1));

  String? get _uid => _auth.currentUser?.uid;

  /// Deterministic id from the sorted participant pair, so opening a chat from
  /// two different entry points can never create two threads between the same
  /// two people.
  String conversationIdFor(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Stream<List<Conversation>> watchConversations() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);

    return _db
        .collection('conversations')
        .where('participant_ids', arrayContains: uid)
        .orderBy('updated_at', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              if (!_blocks.anyBlocked(
                ((doc.data()['participant_ids'] as List?) ?? const [])
                    .map((id) => id as String?),
              ))
                _toConversation(doc.id, doc.data(), uid),
          ],
        );
  }

  Stream<List<Message>> watchMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sent_at', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              Message(
                id: doc.id,
                senderId: doc.get('sender_id') as String? ?? '',
                text: doc.get('text') as String? ?? '',
                sentAt:
                    (doc.data()['sent_at'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                // hasPendingWrites means this is the local echo of a write
                // that hasn't reached the server yet — exactly the offline
                // queue case.
                status: doc.metadata.hasPendingWrites
                    ? MessageStatus.sending
                    : MessageStatus.sent,
              ),
          ],
        );
  }

  Future<Result<void>> send({
    required String conversationId,
    required String otherUserId,
    required String text,
    String? otherUserName,
    String? aboutProductId,
  }) async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    if (uid == null) {
      return const Err(
        AuthFailure(
          'Sign in to send messages',
          reason: FailureReason.signInToMessage,
        ),
      );
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) return const Success(null);
    if (trimmed.length > 2000) {
      return const Err(
        ServerFailure(
          'Message is too long',
          reason: FailureReason.messageTooLong,
        ),
      );
    }

    final wait = _limiter.check(uid);
    if (wait != null) {
      return const Err(
        RateLimitedFailure(
          'You are sending messages too quickly',
          reason: FailureReason.messagingTooFast,
        ),
      );
    }

    final convRef = _db.collection('conversations').doc(conversationId);

    try {
      // NOT awaited past the local write: Firestore's offline queue persists
      // this and replays it on reconnect, so awaiting the server round-trip
      // would block the UI for a message that is already safely queued.
      // participant_names is what the conversation list renders. Written on
      // every send rather than only at creation, so a display-name change
      // eventually propagates without a migration — and so a conversation
      // created by the other side still gets our name attached.
      final names = <String, String>{
        uid: user!.displayName ?? '',
        if (otherUserName != null && otherUserName.isNotEmpty)
          otherUserId: otherUserName,
      };

      await convRef.set({
        'participant_ids': [uid, otherUserId],
        'participant_names': names,
        'updated_at': FieldValue.serverTimestamp(),
        'last_message': trimmed,
        if (aboutProductId != null) 'about_product_id': aboutProductId,
      }, SetOptions(merge: true),);

      await convRef.collection('messages').add({
        'sender_id': uid,
        'text': trimmed,
        'sent_at': FieldValue.serverTimestamp(),
      });

      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(
          e.message ?? 'Message failed',
          code: e.code,
          reason: FailureReason.messageFailed,
        ),);
    }
  }

  /// Resolves the other participant's display name.
  ///
  /// Falls back to a neutral word rather than "Unknown", which reads as an
  /// error to the user when it is really just a name we have not cached yet.
  static String _otherName(
    Map<String, dynamic> data,
    List<String> participants,
    String uid,
  ) {
    final otherId = participants.firstWhere((p) => p != uid, orElse: () => '');
    final names = data['participant_names'] as Map<String, dynamic>?;
    final name = names?[otherId] as String?;
    // Empty, not a word. The widget rendering this has a BuildContext and can
    // say "Someone" in the reader's language; this layer cannot.
    return name ?? '';
  }

  Conversation _toConversation(
    String id,
    Map<String, dynamic> data,
    String uid,
  ) {
    final participants = [
      for (final p in (data['participant_ids'] as List? ?? [])) p as String,
    ];
    return Conversation(
      id: id,
      participantIds: participants,
      otherUserName: _otherName(data, participants, uid),
      updatedAt:
          (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['last_message'] as String?,
      unreadCount: (data['unread_$uid'] as num?)?.toInt() ?? 0,
      aboutProductId: data['about_product_id'] as String?,
    );
  }
}
