import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/features/notifications/data/repositories/notification_repository.dart';
import 'package:wave/features/notifications/domain/notification_route.dart';

/// Top-level background handler.
///
/// MUST be a top-level function with this annotation — Flutter spawns a
/// separate isolate for background messages, and an instance method or closure
/// cannot be reached from it. Getting this wrong produces a handler that works
/// in the foreground and silently does nothing in the background, which is
/// exactly when it matters.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Deliberately minimal. This isolate has no app state, no DI container and a
  // short budget before the OS kills it. Displaying the notification is the
  // platform's job; anything else waits until the app is open.
  debugPrint('Background push: ${message.data['type']}');
}

/// Wires FCM into the running app: token lifecycle, foreground display, and
/// what happens when someone taps.
class PushHandler {
  PushHandler(this._messaging, this._repository);

  final FirebaseMessaging _messaging;
  final NotificationRepository _repository;

  StreamSubscription<RemoteMessage>? _onOpened;
  StreamSubscription<RemoteMessage>? _onForeground;
  StreamSubscription<String>? _onTokenRefresh;

  /// [navigate] is injected rather than reaching for a global router, so the
  /// handler can be tested and so a tap arriving before the router exists
  /// cannot crash the app.
  Future<void> start({required void Function(String route) navigate}) async {
    // Idempotent. `start` is called once from the app shell today, but a handler
    // registered twice shows every push twice, and that is a bug users report
    // as "the app is spamming me" rather than as a duplicate subscription.
    await dispose();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _repository.registerDeviceToken();

    // Tokens rotate — on reinstall, on restore to a new device, and
    // occasionally for no visible reason. A stale token is a notification
    // delivered to nobody.
    _onTokenRefresh = _messaging.onTokenRefresh.listen((_) {
      _repository.registerDeviceToken();
    });

    // A tap that launched the app from terminated state arrives here once,
    // and only here — it is not replayed on the stream below.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleTap(initial, navigate);
    }

    _onOpened = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _handleTap(message, navigate),
    );

    // Assigned like the other two. An unassigned subscription cannot be
    // cancelled, so a second `start()` — after a re-auth, or a hot reload —
    // would leave two handlers running and show every foreground push twice.
    _onForeground = FirebaseMessaging.onMessage.listen(_handleForeground);
  }

  void _handleTap(RemoteMessage message, void Function(String) navigate) {
    final route = NotificationRoute.resolve(message.data);
    if (route == null) return;
    navigate(route);
  }

  /// A push arriving while the user is already looking at the app.
  ///
  /// Suppressed if they turned that channel off. The server filters by topic
  /// too, but a device can hold a subscription the server has not caught up
  /// with yet, and showing a marketing banner to someone who just opted out is
  /// the exact failure the preference centre exists to prevent.
  Future<void> _handleForeground(RemoteMessage message) async {
    final channel = NotificationRoute.channelFor(message.data);
    final prefs = await _repository.preferences();
    if (prefs[channel] == false) return;

    // In-app banner rendering belongs to the UI layer; this is where it hooks
    // in. Deliberately not a system notification — the app is already open.
    debugPrint('Foreground push on ${channel.name}: ${message.notification?.title}');
  }

  Future<void> dispose() async {
    await _onForeground?.cancel();
    await _onOpened?.cancel();
    await _onTokenRefresh?.cancel();
  }
}

/// Convenience for wiring [PushHandler] to GoRouter at the call site.
void Function(String) routerNavigator(GoRouter router) =>
    (route) => router.push(route);
