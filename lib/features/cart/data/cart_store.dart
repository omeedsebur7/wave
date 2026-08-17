import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the cart across app restarts.
///
/// The cart was in-memory only. It survived a guest upgrading to an account —
/// the BLoC is a singleton and the session never ends — so the promise "anything
/// in your cart comes with you" was true for that specific claim. It did not
/// survive the OS killing the app, which on the low-end Android devices common
/// in this market happens constantly and without warning.
///
/// Stored locally rather than in Firestore, deliberately. A cart is an intention,
/// not a commitment: syncing it would mean a guest's cart needs a server-side
/// identity before they have one, and an abandoned cart would become a document
/// somebody pays to store and eventually has to garbage-collect. Local storage
/// costs nothing and matches how long the intention actually lasts.
///
/// Only ids and quantities are stored — never prices. A restored cart re-reads
/// every product, so a price change between sessions shows the new price rather
/// than a stale one someone might reasonably expect to be honoured.
class CartStore {
  CartStore(this._prefs);

  static const _key = 'cart_v1';

  /// Anything older than this is discarded on load.
  ///
  /// A fortnight-old cart is not a shopping session, it is archaeology — and
  /// restoring it means showing someone items they have forgotten wanting, at
  /// prices that have moved, from sellers who may have gone.
  static const maxAge = Duration(days: 14);

  final SharedPreferences _prefs;

  Future<void> save(List<({String productId, int quantity})> lines) async {
    if (lines.isEmpty) {
      await _prefs.remove(_key);
      return;
    }

    await _prefs.setString(
      _key,
      jsonEncode({
        'saved_at': DateTime.now().toIso8601String(),
        'lines': [
          for (final line in lines)
            {'product_id': line.productId, 'quantity': line.quantity},
        ],
      }),
    );
  }

  /// Returns the stored ids and quantities, or empty if there is nothing usable.
  ///
  /// Never throws. A corrupted entry — a schema change, a half-written string —
  /// is discarded rather than surfaced: losing a cart is a small annoyance, and
  /// failing to open the app because of one is not.
  List<({String productId, int quantity})> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final savedAt = DateTime.tryParse(decoded['saved_at'] as String? ?? '');
      if (savedAt == null || DateTime.now().difference(savedAt) > maxAge) {
        return const [];
      }

      return [
        for (final line in (decoded['lines'] as List? ?? const []))
          if (line is Map &&
              line['product_id'] is String &&
              line['quantity'] is int &&
              (line['quantity'] as int) > 0)
            (
              productId: line['product_id'] as String,
              quantity: line['quantity'] as int,
            ),
      ];
    } catch (_) {
      // Discarded silently and cleared, so a bad entry cannot fail twice.
      _prefs.remove(_key);
      return const [];
    }
  }

  Future<void> clear() => _prefs.remove(_key);
}
