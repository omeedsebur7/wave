@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/features/orders/domain/entities/order.dart';
import 'package:wave/features/orders/presentation/widgets/order_tracker.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

/// Golden tests locking in the §3.2 / §3.7 design tokens (§6).
///
/// The contrast test next door proves the MATH is right. These prove the
/// tokens are actually reaching the screen — a token can be perfectly
/// compliant and still be wired to nothing, or overridden by a stray
/// `Color(0xFF...)` three widgets down. Only a rendered pixel catches that.
///
/// Regenerate after an intentional token change:
///     flutter test --update-goldens test/golden
///
/// A diff you did not expect is the point. Do not update goldens to make a
/// failure go away without looking at what moved.
void main() {
  Widget swatchSheet(Brightness brightness) {
    final theme = brightness == Brightness.light
        ? AppTheme.light(const Locale('en'))
        : AppTheme.dark(const Locale('en'));

    return MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          final c = context.waveColors;
          final t = context.trustColors;

          return Scaffold(
            backgroundColor: c.background,
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Display 32/40', style: context.texts.displayLarge),
                  Text('Headline 24/32', style: context.texts.headlineMedium),
                  Text('Title 18/24', style: context.texts.titleMedium),
                  Text('Body 15/22', style: context.texts.bodyMedium),
                  Text('Caption 13/18', style: context.texts.bodySmall),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (name, colour) in [
                        ('primary', c.primary),
                        ('accent-int', c.accentInteractive),
                        ('success', c.success),
                        ('warning', c.warning),
                        ('error', c.error),
                        ('info', c.info),
                      ])
                        _Swatch(name: name, colour: colour),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (name, colour) in [
                        ('bronze', t.bronze),
                        ('silver', t.silver),
                        ('gold', t.gold),
                        ('platinum', t.platinum),
                      ])
                        _Swatch(name: name, colour: colour),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TrustBadge(tier: TrustTier.bronze),
                      TrustBadge(tier: TrustTier.silver),
                      TrustBadge(tier: TrustTier.gold),
                      TrustBadge(tier: TrustTier.platinum),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const OrderTracker(stage: CustomerOrderStage.onTheWay),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius:
                              BorderRadius.circular(WaveSurfaces.radiusChip),
                          boxShadow: context.surfaces.resting,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 80,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius:
                              BorderRadius.circular(WaveSurfaces.radiusCard),
                          boxShadow: context.surfaces.raised,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // The only tier carrying the accent glow — if this ever
                      // renders identically to the two beside it, the glow
                      // token has been lost.
                      Container(
                        width: 80,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius:
                              BorderRadius.circular(WaveSurfaces.radiusSheet),
                          boxShadow: context.surfaces.floating,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  group('Design token goldens', () {
    testWidgets('light mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(swatchSheet(Brightness.light));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tokens_light.png'),
      );
    });

    testWidgets('dark mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(swatchSheet(Brightness.dark));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tokens_dark.png'),
      );
    });
  });
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.colour});

  final String name;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 40,
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
          ),
        ),
        const SizedBox(height: 4),
        // Rendered ON the background, so the golden also captures whether the
        // label is legible against it.
        Text(name, style: context.texts.bodySmall),
      ],
    );
  }
}
