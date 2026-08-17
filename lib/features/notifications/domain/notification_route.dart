import 'package:wave/app/router/routes.dart';
import 'package:wave/features/notifications/domain/entities/app_notification.dart';

/// Resolves a push payload to an in-app destination.
///
/// Extracted as a pure function because notification routing is the classic
/// place bugs hide: it only runs when someone taps a push, often from a cold
/// start, on a device you do not have. It is close to impossible to exercise by
/// hand and trivial to test in isolation.
///
/// The contract with the backend is that every push carries a `type` and the
/// ids that type needs. Anything unrecognised — from a newer server than this
/// build — lands somewhere sensible rather than nowhere.
abstract final class NotificationRoute {
  /// Returns a route path, or null when the payload names nothing we can open.
  static String? resolve(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    return switch (type) {
      'order_update' => _ifPresent(
          data['order_id'],
          Routes.orderDetailPath,
        ),
      'order_placed' => _ifPresent(
          data['order_id'],
          (_) => Routes.sellerOrders,
        ),
      'chat_message' => Routes.chat,
      'new_review' || 'new_rating' => Routes.sellerStats,
      'reel_like' || 'reel_comment' => _ifPresent(
          data['reel_id'],
          Routes.reelDetailPath,
        ),
      'new_follower' => _ifPresent(
          data['follower_id'],
          Routes.sellerProfilePath,
        ),
      'product_back_in_stock' => _ifPresent(
          data['product_id'],
          Routes.productDetailPath,
        ),
      // Marketing pushes may carry an arbitrary in-app path. Validated below
      // rather than trusted — a push is remote input, and following an
      // arbitrary string from it is how you get an open redirect.
      'marketing' => _safePath(data['path'] as String?),
      // An unknown type from a newer server: the notification centre always
      // exists and shows whatever it was, which beats swallowing the tap.
      _ => Routes.notifications,
    };
  }

  /// The channel a payload belongs to, so a push arriving while the app is in
  /// the foreground can be suppressed if the user turned that channel off.
  static NotificationChannel channelFor(Map<String, dynamic> data) {
    return switch (data['type'] as String?) {
      'order_update' || 'order_placed' => NotificationChannel.orders,
      'chat_message' => NotificationChannel.chat,
      'reel_like' ||
      'reel_comment' ||
      'new_follower' ||
      'new_review' ||
      'new_rating' =>
        NotificationChannel.social,
      'marketing' => NotificationChannel.marketing,
      // An unrecognised type is treated as social, never as marketing —
      // guessing wrong in the marketing direction means sending someone a
      // message they explicitly opted out of.
      _ => NotificationChannel.social,
    };
  }

  static String? _ifPresent(Object? id, String Function(String) build) {
    final value = id as String?;
    if (value == null || value.isEmpty) return null;
    return build(value);
  }

  /// Only in-app paths. Rejects absolute URLs, protocol-relative URLs, and
  /// traversal — a marketing push must not be able to point the app at an
  /// arbitrary destination.
  static String? _safePath(String? path) {
    if (path == null || path.isEmpty) return null;
    if (!path.startsWith('/')) return null;
    if (path.startsWith('//')) return null;
    if (path.contains('..')) return null;
    if (path.contains('://')) return null;
    return path;
  }
}
