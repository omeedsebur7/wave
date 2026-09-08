import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/design_system/components/wave_button.dart';

import '../helpers/pump_app.dart';

void main() {
  group('WaveErrorView', () {
    testWidgets('shows the retry action only when one is given',
        (tester) async {
      await tester.pumpWave(
        const WaveErrorView(title: 'Gone wrong', message: 'Try later'),
      );
      expect(find.byType(WaveButton), findsNothing);

      await tester.pumpWave(
        WaveErrorView(
          title: 'Gone wrong',
          message: 'Try later',
          onRetry: () {},
        ),
      );
      expect(find.byType(WaveButton), findsOneWidget);
    });

    testWidgets('the retry callback fires', (tester) async {
      var tapped = false;
      await tester.pumpWave(
        WaveErrorView(
          title: 'Gone wrong',
          message: 'Try later',
          onRetry: () => tapped = true,
        ),
      );
      await tester.tap(find.byType(WaveButton));
      expect(tapped, isTrue);
    });

    testWidgets('the empty variant defaults to an inviting action label',
        (tester) async {
      // An empty state is an invitation to act, not a failure report — the
      // default label reflects that.
      await tester.pumpWave(
        WaveErrorView.empty(
          title: 'Nothing here',
          message: 'Add something',
          onRetry: () {},
        ),
      );
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('long copy does not overflow at large text scale',
        (tester) async {
      await tester.pumpWave(
        const WaveErrorView(
          title: 'Something went wrong loading the thing you asked for',
          message: 'This is a deliberately long message to push the layout '
              'past its comfortable width and check that it wraps instead of '
              'overflowing the screen.',
        ),
        textScale: 1.4,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
