import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/notifications/domain/entities/app_notification.dart';
import 'package:wave/features/notifications/domain/notification_route.dart';

void main() {
  group('Notification routing', () {
    test('an order update opens that order', () {
      expect(
        NotificationRoute.resolve({
          'type': 'order_update',
          'order_id': 'abc123',
        }),
        '/profile/orders/abc123',
      );
    });

    test('a new order sends the seller to their fulfilment queue', () {
      expect(
        NotificationRoute.resolve({
          'type': 'order_placed',
          'order_id': 'abc123',
        }),
        '/profile/selling',
      );
    });

    test('a like or comment opens the Reel', () {
      expect(
        NotificationRoute.resolve({'type': 'reel_like', 'reel_id': 'r1'}),
        '/reels/r1',
      );
      expect(
        NotificationRoute.resolve({'type': 'reel_comment', 'reel_id': 'r1'}),
        '/reels/r1',
      );
    });

    test('an unknown type still lands somewhere, not nowhere', () {
      // A newer server sending a type this build has never heard of must not
      // swallow the tap — the notification centre always exists.
      expect(
        NotificationRoute.resolve({'type': 'something_from_the_future'}),
        '/notifications',
      );
      expect(NotificationRoute.resolve({}), '/notifications');
    });

    test('a payload missing the id it needs resolves to nothing', () {
      // Better than routing to '/profile/orders/null'.
      expect(NotificationRoute.resolve({'type': 'order_update'}), isNull);
      expect(
        NotificationRoute.resolve({'type': 'order_update', 'order_id': ''}),
        isNull,
      );
    });
  });

  group('Marketing paths are remote input, not trusted', () {
    test('accepts a plain in-app path', () {
      expect(
        NotificationRoute.resolve({'type': 'marketing', 'path': '/marketplace'}),
        '/marketplace',
      );
    });

    test('rejects an absolute URL', () {
      // Following one would turn a push into an open redirect.
      expect(
        NotificationRoute.resolve({
          'type': 'marketing',
          'path': 'https://evil.example/phish',
        }),
        isNull,
      );
    });

    test('rejects a protocol-relative URL', () {
      expect(
        NotificationRoute.resolve({
          'type': 'marketing',
          'path': '//evil.example/phish',
        }),
        isNull,
      );
    });

    test('rejects path traversal', () {
      expect(
        NotificationRoute.resolve({
          'type': 'marketing',
          'path': '/reels/../../admin',
        }),
        isNull,
      );
    });

    test('rejects a relative path with no leading slash', () {
      expect(
        NotificationRoute.resolve({'type': 'marketing', 'path': 'marketplace'}),
        isNull,
      );
    });

    test('rejects an empty or missing path', () {
      expect(
        NotificationRoute.resolve({'type': 'marketing', 'path': ''}),
        isNull,
      );
      expect(NotificationRoute.resolve({'type': 'marketing'}), isNull);
    });
  });

  group('Channel classification', () {
    test('maps each known type to its channel', () {
      expect(
        NotificationRoute.channelFor({'type': 'order_update'}),
        NotificationChannel.orders,
      );
      expect(
        NotificationRoute.channelFor({'type': 'chat_message'}),
        NotificationChannel.chat,
      );
      expect(
        NotificationRoute.channelFor({'type': 'reel_like'}),
        NotificationChannel.social,
      );
      expect(
        NotificationRoute.channelFor({'type': 'marketing'}),
        NotificationChannel.marketing,
      );
    });

    test('never classifies an unknown type as marketing', () {
      // Guessing wrong in the marketing direction means showing something to
      // someone who explicitly opted out of exactly that.
      for (final type in ['mystery', '', 'order_something_new']) {
        expect(
          NotificationRoute.channelFor({'type': type}),
          isNot(NotificationChannel.marketing),
        );
      }
      expect(
        NotificationRoute.channelFor({}),
        isNot(NotificationChannel.marketing),
      );
    });
  });
}
