import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/utils/money.dart';

void main() {
  group('Money formatting', () {
    test('IQD has no decimal places', () {
      // Dinars are quoted whole. "25,000.00 IQD" is wrong and looks amateur.
      expect(Money.decimalsFor('IQD'), 0);
      expect(Money.format(25000, 'IQD'), contains('25,000'));
      expect(Money.format(25000, 'IQD'), isNot(contains('.00')));
    });

    test('IQD is suffixed, not prefixed', () {
      expect(Money.format(1000, 'IQD').trim().endsWith('IQD'), isTrue);
    });

    test('USD keeps two decimal places', () {
      expect(Money.decimalsFor('USD'), 2);
    });

    test('an unknown currency defaults to two decimals rather than crashing', () {
      expect(Money.decimalsFor('XYZ'), 2);
    });

    test('zero formats cleanly', () {
      expect(Money.format(0, 'IQD'), contains('0'));
    });
  });
}
