import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/notifications/domain/entities/app_notification.dart';

void main() {
  group('Notification channel defaults (§4, §7)', () {
    test('marketing is OFF by default — consent is given, not assumed', () {
      expect(NotificationChannel.marketing.defaultEnabled, isFalse);
    });

    test('order updates are ON — someone who bought something wants them', () {
      expect(NotificationChannel.orders.defaultEnabled, isTrue);
      expect(NotificationChannel.chat.defaultEnabled, isTrue);
      expect(NotificationChannel.social.defaultEnabled, isTrue);
    });

    test('every channel is named by the localized mapper, not by the enum',
        () {
      // This replaces an assertion on `NotificationChannel.label`, a field that
      // held four English strings. The test passed for every one of them, which
      // is precisely the problem: "has a non-empty label" is satisfied by an
      // untranslated label, so the test endorsed the bug it looked like it was
      // guarding against.
      //
      // The label now comes from the ARB via `_channelLabel`, so what is worth
      // asserting is that a key exists for every channel — checked here against
      // the template ARB rather than through a widget pump.
      final arb = json.decode(
        File('lib/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

      for (final channel in NotificationChannel.values) {
        final key = 'notif'
            '${channel.name[0].toUpperCase()}${channel.name.substring(1)}';
        expect(
          arb[key],
          isNotNull,
          reason: '$key is missing from app_en.arb, so the notification '
              'preferences screen cannot name the ${channel.name} channel',
        );
      }
    });
  });
}
