import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/features/cart/data/cart_store.dart';

/// Cart persistence.
///
/// The cart was in-memory only. It survived a guest upgrading to an account —
/// same session, singleton BLoC — so the promise "anything in your cart comes
/// with you" held for that claim. It did not survive the OS killing the app,
/// which on the low-end Android devices common in this market happens
/// constantly and without warning.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CartStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = CartStore(await SharedPreferences.getInstance());
  });

  group('Round trip', () {
    test('an empty store loads nothing', () {
      expect(store.load(), isEmpty);
    });

    test('saved lines come back', () async {
      await store.save([
        (productId: 'p1', quantity: 2),
        (productId: 'p2', quantity: 1),
      ]);

      final loaded = store.load();
      expect(loaded.length, 2);
      expect(loaded.first.productId, 'p1');
      expect(loaded.first.quantity, 2);
    });

    test('saving an empty cart clears the entry', () async {
      await store.save([(productId: 'p1', quantity: 1)]);
      await store.save([]);
      expect(store.load(), isEmpty);
    });

    test('clear removes everything', () async {
      await store.save([(productId: 'p1', quantity: 1)]);
      await store.clear();
      expect(store.load(), isEmpty);
    });
  });

  group('What is deliberately not stored', () {
    test('prices are absent from the serialised form', () async {
      await store.save([(productId: 'p1', quantity: 2)]);
      final raw =
          (await SharedPreferences.getInstance()).getString('cart_v1')!;

      // A restored cart re-reads every product, so it shows what things cost
      // now — not what they cost last week, at a price someone might
      // reasonably expect to be honoured.
      expect(raw, isNot(contains('price')));
      expect(raw, contains('p1'));
    });
  });

  group('Corruption and staleness are survivable', () {
    test('a fortnight-old cart is discarded', () async {
      final stale = DateTime.now().subtract(const Duration(days: 15));
      SharedPreferences.setMockInitialValues({
        'cart_v1':
            '{"saved_at":"${stale.toIso8601String()}",'
            '"lines":[{"product_id":"p1","quantity":1}]}',
      });
      final s = CartStore(await SharedPreferences.getInstance());

      // Not a shopping session, archaeology — items someone has forgotten
      // wanting, at prices that have moved, from sellers who may have gone.
      expect(s.load(), isEmpty);
    });

    test('a cart from yesterday survives', () async {
      final recent = DateTime.now().subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        'cart_v1':
            '{"saved_at":"${recent.toIso8601String()}",'
            '"lines":[{"product_id":"p1","quantity":3}]}',
      });
      final s = CartStore(await SharedPreferences.getInstance());
      expect(s.load().single.quantity, 3);
    });

    test('malformed JSON is discarded rather than thrown', () async {
      // Losing a cart is a small annoyance. Failing to open the app because of
      // one is not.
      SharedPreferences.setMockInitialValues({'cart_v1': 'not json at all'});
      final s = CartStore(await SharedPreferences.getInstance());
      expect(s.load(), isEmpty);
    });

    test('a bad entry cannot fail twice', () async {
      SharedPreferences.setMockInitialValues({'cart_v1': '{"lines":'});
      final prefs = await SharedPreferences.getInstance();
      CartStore(prefs).load();
      
      // Removed the unnecessary cascade that was causing the analyzer warning
      


      
      expect(prefs.getString('cart_v1'), isNull);
    });

    test('lines missing fields are skipped, not guessed at', () async {
      SharedPreferences.setMockInitialValues({
        'cart_v1':
            '{"saved_at":"${DateTime.now().toIso8601String()}","lines":['
            '{"product_id":"good","quantity":1},'
            '{"quantity":2},'
            '{"product_id":"nonpositive","quantity":0},'
            '{"product_id":"wrongtype","quantity":"two"}]}',
      });
      final s = CartStore(await SharedPreferences.getInstance());
      expect(s.load().map((l) => l.productId), ['good']);
    });

    test('a missing timestamp is treated as unusable', () async {
      // Without one there is no way to know whether it is stale, and guessing
      // "recent" is the wrong direction to guess.
      SharedPreferences.setMockInitialValues({
        'cart_v1': '{"lines":[{"product_id":"p1","quantity":1}]}',
      });
      final s = CartStore(await SharedPreferences.getInstance());
      expect(s.load(), isEmpty);
    });
  });
}
