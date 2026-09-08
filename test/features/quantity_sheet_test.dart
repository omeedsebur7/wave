import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_price.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/presentation/pages/product_detail_page.dart';

import '../support/wave_test_app.dart';

/// A real Product rather than a mock.
///
/// Product is a plain Equatable value class, so a mock buys nothing and costs
/// a stub for every getter the widget tree touches — StockLine alone reads
/// inStock, isLowStock and stock, and an unstubbed getter throws at call time.
/// createdAt is fixed: a DateTime.now() here would make every golden unstable.
Product buildProduct({int stock = 5, int priceMinor = 15000}) => Product(
      id: 'p123',
      sellerId: 's1',
      sellerName: 'فرۆشگای تێست',
      title: 'قاوەی عەرەبی ئۆرجیناڵ - بڕاندی تێست',
      description: 'وەسفی کاڵا بۆ تێست.',
      priceMinor: priceMinor,
      currency: 'IQD',
      imageUrls: const [],
      stock: stock,
      createdAt: DateTime.utc(2026, 9),
    );

void main() {
  late Product product;

  setUp(() {
    product = buildProduct();
  });

  /// Mirrors _StickyCta's real call site: caller-owned ValueNotifier, footer
  /// wrapped in a ValueListenableBuilder, disposal in a finally block. The
  /// result goes into a SnackBar so the test can read what the sheet returned.
  Widget buildHarness() {
    return Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final quantity = ValueNotifier<int>(1);
              final messenger = ScaffoldMessenger.of(context);

              try {
                final chosen = await WaveSheet.show<int>(
                  context: context,
                  title: 'هەڵبژاردنی بڕ',
                  builder: (_) =>
                      QuantitySheet(product: product, quantity: quantity),
                  footer: ValueListenableBuilder<int>(
                    valueListenable: quantity,
                    builder: (sheetContext, qty, _) => WaveButton(
                      label: 'زیادکردن',
                      expand: true,
                      onPressed: () => Navigator.of(sheetContext).pop(qty),
                    ),
                  ),
                );

                messenger.showSnackBar(
                  SnackBar(content: Text('Returned: $chosen')),
                );
              } finally {
                quantity.dispose();
              }
            },
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    );
  }

  /// The subtotal is the LAST WavePrice in the tree. The sheet renders no
  /// other price today, but the PDP behind it might, so this stays explicit.
  int subtotalOf(WidgetTester tester) =>
      tester.widget<WavePrice>(find.byType(WavePrice).last).amountMinor;

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
  }

  group('QuantitySheet goldens', () {
    for (final (name, locale, brightness) in [
      ('light_en', const Locale('en'), Brightness.light),
      ('dark_en', const Locale('en'), Brightness.dark),
      ('light_ckb', const Locale('ckb'), Brightness.light),
      ('dark_ckb', const Locale('ckb'), Brightness.dark),
    ]) {
      testWidgets('chrome $name', (tester) async {
        await tester.pumpWave(
          buildHarness(),
          locale: locale,
          brightness: brightness,
        );
        await openSheet(tester);

        // MaterialApp, not the sheet: the sheet lives in an overlay, and the
        // scrim is part of what this golden is checking.
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/qty_sheet_$name.png'),
        );
      });
    }

    // 1.4x is the app's own clamp (app.dart), so this is the worst case a
    // real user can produce.
    testWidgets('survives 1.4x text scale', (tester) async {
      await tester.pumpWave(
        buildHarness(),
        textScale: 1.4,
      );
      await openSheet(tester);

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/qty_sheet_ckb_1.4x.png'),
      );
    });

    // The footer must clear the keyboard, or a form in a sheet is unusable.
    testWidgets('lifts above the keyboard', (tester) async {
      await tester.pumpWave(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              viewInsets: const EdgeInsets.only(bottom: 300),
            ),
            child: buildHarness(),
          ),
        ),
      );
      await openSheet(tester);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/qty_sheet_keyboard.png'),
      );
    });
  });

  group('QuantitySheet behaviour', () {
    testWidgets('stepping updates the subtotal', (tester) async {
      await tester.pumpWave(buildHarness());
      await openSheet(tester);

      expect(subtotalOf(tester), 15000);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(subtotalOf(tester), 30000);
    });

    // The bug the ValueNotifier exists to prevent: a footer built outside the
    // sheet body cannot read its state, and popped a hardcoded 1.
    testWidgets('footer returns the chosen quantity, not 1', (tester) async {
      await tester.pumpWave(buildHarness());
      await openSheet(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('زیادکردن'));
      await tester.pumpAndSettle();

      expect(find.text('Returned: 3'), findsOneWidget);
    });

    // Bounds live in the stepper, not the caller: a quantity above stock is a
    // checkout failure moved later in the funnel.
    testWidgets('cannot exceed product stock', (tester) async {
      await tester.pumpWave(buildHarness());
      await openSheet(tester);

      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      }

      expect(subtotalOf(tester), 75000); // 5 in stock x 15000
    });

    testWidgets('cannot go below one', (tester) async {
      await tester.pumpWave(buildHarness());
      await openSheet(tester);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();

      expect(subtotalOf(tester), 15000);
    });

    testWidgets('dismissing by scrim returns null', (tester) async {
      await tester.pumpWave(buildHarness());
      await openSheet(tester);

      // Top-left corner is scrim in LTR and in RTL alike — the sheet is
      // anchored to the bottom in both.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Returned: null'), findsOneWidget);
    });

    testWidgets('closing by the header button returns null', (tester) async {
      await tester.pumpWave(buildHarness());
      await openSheet(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Returned: null'), findsOneWidget);
    });
  });
}
