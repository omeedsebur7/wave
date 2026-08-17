import 'package:equatable/equatable.dart';

/// Notification channels (§4). These are the same four the preference centre
/// toggles, and the same four the FCM topic subscriptions map to — one enum,
/// so a channel can't exist in the UI without a matching send path.
enum NotificationChannel {
  orders,
  chat,
  social,
  marketing;

  // No `label` field. There was one, holding four English strings, and it was
  // superseded by `_channelLabel` on the preferences page — which is the only
  // place a channel is named to a user, and the only place with a BuildContext
  // to name it in their language. The field survived as a second, untranslated
  // source of truth that nothing rendered and any new screen might have.

  /// Order updates default on — someone who bought something wants to know
  /// where it is. Marketing defaults off: consent is given, not assumed (§7).
  bool get defaultEnabled => this != NotificationChannel.marketing;
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.deepLink,
  });

  final String id;
  final NotificationChannel channel;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  /// Route path to open on tap, e.g. `/profile/orders/abc123`.
  final String? deepLink;

  @override
  List<Object?> get props => [id, read];
}
