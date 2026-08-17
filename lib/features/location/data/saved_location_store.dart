import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/features/location/domain/entities/delivery_location.dart';

/// Remembers the last confirmed delivery point.
///
/// Local, not on the profile. A home location is the most sensitive thing this
/// app touches, and syncing it would put it in a document that survives the
/// device, gets backed up, and has to be reasoned about in the deletion cascade.
/// Keeping it on the phone means the only copies that leave are the ones
/// attached to an order the buyer chose to place.
///
/// Exists so the picker opens on somewhere useful. Without it every Buy Now
/// starts zoomed out over the country, which turns a two-tap purchase into a
/// map-navigation exercise — and the map is already friction on the app's
/// core path.
class SavedLocationStore {
  SavedLocationStore(this._prefs);

  static const _key = 'last_delivery_location_v1';

  /// After this the pin is more likely to mislead than help — people move, and
  /// a stale pin confirmed without looking sends a courier to an old address.
  static const maxAge = Duration(days: 90);

  final SharedPreferences _prefs;

  Future<void> save(DeliveryLocation location) async {
    if (!location.isValid) return;

    await _prefs.setString(
      _key,
      jsonEncode({
        ...location.toJson(),
        'saved_at': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// The last point, or null if there is nothing usable.
  ///
  /// Never throws: a corrupted entry means the map opens at the default, which
  /// is a mild inconvenience, where an exception here would break Buy Now.
  DeliveryLocation? last() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final savedAt = DateTime.tryParse(decoded['saved_at'] as String? ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > maxAge) {
        return null;
      }

      final location = DeliveryLocation.fromJson(decoded);
      // Re-tagged: whatever it was when captured, reading it back makes it a
      // remembered point, and the picker shows that differently.
      return location?.copyWith(setBy: LocationSource.saved);
    } catch (_) {
      _prefs.remove(_key);
      return null;
    }
  }

  /// Called from account deletion and sign-out. A delivery pin left on a shared
  /// device is the next person's map centred on the last person's home.
  Future<void> clear() => _prefs.remove(_key);
}
