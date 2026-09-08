import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/widgets/wave_quantity_stepper.dart';

import '../support/wave_test_app.dart';

/// Fixed frame so the goldens are about the stepper, not about how a Center
/// lays out in an 800x600 default surface.
Widget _harness(int value, {int max = 10}) => Center(
      child: WaveQuantityStepper(
        value: value,
        max: max,
        onChanged: (_) {},
      ),
    );

void main() {
  group('WaveQuantityStepper', () {
    // Values, in one locale/theme. Value affects which buttons are disabled
    // and how wide the number is — neither of which interacts with theme or
    // direction, so a full 3x2x2 matrix would be 12 near-identical files.
    for (final (name, value, max) in const [
      ('min', 1, 10),
      ('mid', 5, 10),
      ('max', 10, 10),
      // Two digits: proves the fixed-width number slot does not resize the
      // row when 9 becomes 10.
      ('two_digit', 10, 99),
    ]) {
      testWidgets('value $name', (tester) async {
        await tester.pumpWave(_harness(value, max: max));
        await expectLater(
          find.byType(WaveQuantityStepper),
          matchesGoldenFile('goldens/stepper_$name.png'),
        );
      });
    }

    // Theme and direction, at a value where both step buttons are enabled.
    for (final (name, locale, brightness) in const [
      ('light_en', Locale('en'), Brightness.light),
      ('dark_en', Locale('en'), Brightness.dark),
      ('light_ckb', Locale('ckb'), Brightness.light),
      ('dark_ckb', Locale('ckb'), Brightness.dark),
    ]) {
      testWidgets('chrome $name', (tester) async {
        await tester.pumpWave(
          _harness(5),
          locale: locale,
          brightness: brightness,
        );
        await expectLater(
          find.byType(WaveQuantityStepper),
          matchesGoldenFile('goldens/stepper_$name.png'),
        );
      });
    }

    // Not a golden — an assertion. P10 requires zero overflow at 1.3x, and
    // an overflow throws rather than rendering, so a golden would just fail
    // opaquely.
    testWidgets('survives 1.3x text scale', (tester) async {
      await tester.pumpWave(
        _harness(10, max: 99),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(WaveQuantityStepper),
        matchesGoldenFile('goldens/stepper_ckb_1.3x.png'),
      );
    });

    // Behaviour, not appearance. Bounds are the stepper's whole contract.
    testWidgets('does not step past its bounds', (tester) async {
      var value = 1;
      await tester.pumpWidget(
        WaveTestApp(
          child: StatefulBuilder(
            builder: (context, setState) => Center(
              child: WaveQuantityStepper(
                value: value,
                max: 3,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(value, 1, reason: 'stepped below min');

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      expect(value, 3, reason: 'stepped past max');
    });
  });
}
