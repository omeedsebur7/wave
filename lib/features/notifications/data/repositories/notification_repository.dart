import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/notifications/domain/entities/app_notification.dart';

/// Notification storage, preferences and FCM token lifecycle (§4, §7).
class NotificationRepository {
  NotificationRepository(this._db, this._auth, this._messaging);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? get _prefsDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('notification_prefs')
        .doc('channels');
  }

  Stream<List<AppNotification>> watchNotifications({int limit = 50}) {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);

    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => [
            for (final doc in snap.docs)
              AppNotification(
                id: doc.id,
                channel: NotificationChannel.values.firstWhere(
                  (c) => c.name == doc.data()['channel'],
                  // An unknown channel from a newer backend lands in social
                  // rather than crashing an older client.
                  orElse: () => NotificationChannel.social,
                ),
                title: doc.data()['title'] as String? ?? '',
                body: doc.data()['body'] as String? ?? '',
                createdAt:
                    (doc.data()['created_at'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
                read: doc.data()['read'] as bool? ?? false,
                deepLink: doc.data()['deep_link'] as String?,
              ),
          ],
        );
  }

  Future<Map<NotificationChannel, bool>> preferences() async {
    final doc = _prefsDoc;
    if (doc == null) {
      return {
        for (final c in NotificationChannel.values) c: c.defaultEnabled,
      };
    }

    final snap = await doc.get();
    final data = snap.data() ?? const <String, dynamic>{};

    // Fall back to the enum's own default per channel rather than a blanket
    // true/false, so a channel added in a later release gets the right default
    // for existing users without a migration.
    return {
      for (final channel in NotificationChannel.values)
        channel: data[channel.name] as bool? ?? channel.defaultEnabled,
    };
  }

  Future<Result<void>> setPreference(
    NotificationChannel channel, {
    required bool enabled,
  }) async {
    final doc = _prefsDoc;
    if (doc == null) {
      return const Err(
        AuthFailure('Not signed in', reason: FailureReason.notSignedIn),
      );
    }

    try {
      await doc.set({channel.name: enabled}, SetOptions(merge: true));

      // Topic subscription mirrors the preference, so an unsubscribed user is
      // not merely filtered client-side — the message is never sent to them.
      // Filtering on the device still costs the user a notification.
      if (enabled) {
        await _messaging.subscribeToTopic(channel.name);
      } else {
        await _messaging.unsubscribeFromTopic(channel.name);
      }

      return const Success(null);
    } on FirebaseException catch (e) {
      return Err(ServerFailure(e.message ?? 'Error', code: e.code));
    }
  }

  /// Called after sign-in and on every token refresh.
  ///
  /// Tokens are stored per-device in a subcollection rather than as one field
  /// on the user, because a person signed in on a phone and a tablet has two
  /// valid tokens and a single field silently loses one of them.
  Future<void> registerDeviceToken() async {
    final uid = _uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .doc(token)
        .set({
      'token': token,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Removes this device's token on sign-out, so the next person to use the
  /// device does not receive the previous user's order updates.
  Future<void> unregisterDeviceToken() async {
    final uid = _uid;
    final token = await _messaging.getToken();
    if (uid == null || token == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .doc(token)
        .delete();
  }

  /// Permission is requested at the moment of first genuine use, never on
  /// first launch — a denied iOS permission cannot be re-requested in-app, only
  /// sent to Settings, so spending the one prompt on a cold start is expensive.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<void> markRead(String notificationId) async {
    final uid = _uid;
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }
}
