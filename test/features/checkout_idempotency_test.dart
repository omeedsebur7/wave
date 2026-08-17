import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/utils/idempotency.dart';

void main() {
  group('Idempotency keys', () {
    test('each generated key is unique', () {
      final keys = {for (var i = 0; i < 500; i++) IdempotencyKey.generate().value};
      expect(keys.length, 500);
    });

    test('a stored key round-trips unchanged', () {
      // This is what makes a retry safe: the key survives being persisted and
      // read back, so a resumed checkout carries the ORIGINAL key rather than
      // minting a fresh one.
      final original = IdempotencyKey.generate();
      final restored = IdempotencyKey.fromStored(original.value);
      expect(restored.value, original.value);
    });

    test('keys are long enough to reject at the function boundary', () {
      // placeOrder rejects anything under 8 characters.
      expect(IdempotencyKey.generate().value.length, greaterThanOrEqualTo(8));
    });
  });
}
