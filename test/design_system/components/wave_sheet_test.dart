import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// تێبینی: دڵنیابە ئەم پاتەی خوارەوە ڕێک ئەو شوێنەیە کە wave_sheet.dartی لێیە
import 'package:wave/core/widgets/wave_sheet.dart';

import '../../support/wave_test_app.dart';

void main() {
  Widget buildHarness({
    bool dismissible = true,
    bool withFooter = true,
  }) {
    return Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              WaveSheet.show<void>(
                context: context,
                title: 'هەڵبژاردنی بڕ',
                dismissible: dismissible,
                footer: withFooter ? const Text('تەواو') : null,
                builder: (context) => const Padding(
                  padding: EdgeInsets.all(16), // چارەسەری int_literals
                  child: Text('ناوەڕۆکی شیتەکە لێرەدا دەبێت.'),
                ),
              );
            },
            child: const Text('Open Sheet'),
          ),
        ),
      ),
    );
  }

  group('WaveSheet Goldens', () {
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

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/sheet_$name.png'),
        );
      });
    }

    testWidgets('survives 1.4x text scale', (tester) async {
      await tester.pumpWave(
        buildHarness(),
        textScale: 1.4, // چارەسەری redundant_argument
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/sheet_ckb_1.4x.png'),
      );
    });

    testWidgets('keyboard visible lifts footer', (tester) async {
      await tester.pumpWave(
        MediaQuery(
          data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 300)),
          child: buildHarness(),
        ),
        // چارەسەری redundant_argument
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/sheet_keyboard_visible.png'),
      );
    });

    testWidgets('non_dismissible hides drag handle and close icon', (tester) async {
      await tester.pumpWave(
        buildHarness(dismissible: false),
        // چارەسەری redundant_argument
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsNothing);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/sheet_non_dismissible.png'),
      );
    });
  });

  group('WaveSheet Behavior', () {
    testWidgets('dismissible: false survives system back gesture', (tester) async {
      await tester.pumpWave(buildHarness(dismissible: false));
      
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      // ignore: avoid_dynamic_calls
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(find.text('ناوەڕۆکی شیتەکە لێرەدا دەبێت.'), findsOneWidget);
    });
  });
}
