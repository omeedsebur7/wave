import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/theme/wave_trust_colors.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

import '../helpers/pump_app.dart';

void main() {
  group('TrustBadge', () {
    testWidgets(
      'always renders an icon AND a text label, never colour alone',
      (tester) async {
        // This is the WCAG 1.4.1 requirement AND the practical guard against
        // "Gold Trusted" being misread as the amber "Low stock" warning, since
        // gold and warning necessarily share a hue family.
        for (final tier in [
          TrustTier.bronze,
          TrustTier.silver,
          TrustTier.gold,
          TrustTier.platinum,
        ]) {
          await tester.pumpWave(TrustBadge(tier: tier));

          expect(find.byType(Icon), findsOneWidget, reason: '${tier.name} icon');
          expect(find.byType(Text), findsOneWidget, reason: '${tier.name} label');

          final label = tester.widget<Text>(find.byType(Text)).data;
          expect(label, isNotNull);
          expect(label, isNotEmpty, reason: '${tier.name} label must not be blank');
        }
      },
    );

    testWidgets('gold and the warning colour are never the same value',
        (tester) async {
      await tester.pumpWave(const TrustBadge(tier: TrustTier.gold));
      final context = tester.element(find.byType(TrustBadge));
      final trust = Theme.of(context).extension<WaveTrustColors>()!;
      final warning = Theme.of(context).colorScheme.error;
      expect(trust.gold, isNot(equals(warning)));
    });

    testWidgets('a new seller shows no tier badge text', (tester) async {
      await tester.pumpWave(const TrustBadge(tier: TrustTier.newSeller));
      expect(find.text('New seller'), findsOneWidget);
      expect(find.text('Gold Trusted'), findsNothing);
    });

    testWidgets('KYC verification shows on an otherwise untiered seller',
        (tester) async {
      await tester.pumpWave(
        const TrustBadge(tier: TrustTier.newSeller, isKycVerified: true),
      );
      expect(find.text('Verified seller'), findsOneWidget);
    });

    testWidgets('a rating-earned tier outranks the KYC label', (tester) async {
      // The tier is the stronger signal — it is built from delivered orders,
      // not from an identity check.
      await tester.pumpWave(
        const TrustBadge(tier: TrustTier.platinum, isKycVerified: true),
      );
      expect(find.text('Top Rated'), findsOneWidget);
      expect(find.text('Verified seller'), findsNothing);
    });

    testWidgets('compact mode still exposes the label to screen readers',
        (tester) async {
      // The text is visually dropped for tight card corners; the semantic
      // label must survive, or the badge becomes colour-only for anyone using
      // a screen reader.
      final handle = tester.ensureSemantics();
      await tester.pumpWave(
        const TrustBadge(tier: TrustTier.gold, compact: true),
      );
      expect(find.text('Gold Trusted'), findsNothing);
      expect(
        find.bySemanticsLabel('Gold Trusted'),
        findsOneWidget,
        reason: 'compact badges must not become colour-only for screen readers',
      );
      handle.dispose();
    });

    testWidgets('survives large dynamic type without overflowing',
        (tester) async {
      await tester.pumpWave(
        const TrustBadge(tier: TrustTier.platinum),
        textScale: 1.4,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWave(
        const TrustBadge(tier: TrustTier.silver),
        brightness: Brightness.dark,
      );
      expect(find.text('Silver Trusted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
