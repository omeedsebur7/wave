import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/orders/presentation/widgets/order_tracker.dart';

import '../helpers/pump_app.dart';

void main() {
  group('OrderTracker', () {
    testWidgets('shows exactly three steps, never the internal states',
        (tester) async {
      await tester.pumpWave(
        const OrderTracker(stage: CustomerOrderStage.confirmed),
      );

      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('On the way'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);

      // The buyer must never see ops detail — that is the whole point of the
      // simplification in §5.2.
      expect(find.text('Packed'), findsNothing);
      expect(find.text('Payment processing'), findsNothing);
      expect(find.text('Handed to courier'), findsNothing);
    });

    testWidgets('announces position as "step N of 3" to screen readers',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWave(
        const OrderTracker(stage: CustomerOrderStage.onTheWay),
      );
      expect(
        find.bySemanticsLabel(RegExp('step 2 of 3')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a cancelled order replaces the tracker rather than faking it',
        (tester) async {
      // Showing a 3-step tracker for a cancelled order would imply it is still
      // coming.
      await tester.pumpWave(
        const OrderTracker(stage: CustomerOrderStage.cancelled),
      );
      expect(find.text('Order cancelled'), findsOneWidget);
      expect(find.text('On the way'), findsNothing);
    });

    testWidgets('renders in RTL without overflowing', (tester) async {
      await tester.pumpWave(
        const OrderTracker(stage: CustomerOrderStage.delivered),
        locale: const Locale('ckb'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives large dynamic type', (tester) async {
      await tester.pumpWave(
        const OrderTracker(stage: CustomerOrderStage.confirmed),
        textScale: 1.4,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
