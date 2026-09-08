import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/tokens/wave_colors.dart';
import 'package:wave/core/theme/tokens/wave_motion.dart';
// WaveFonts and WaveTextStyles both live in wave_typography.dart.
import 'package:wave/core/theme/tokens/wave_spacing.dart';
import 'package:wave/core/theme/tokens/wave_typography.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/theme/wave_trust_colors.dart';

/// WCAG 2.x relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, c) in [
    ('light', WaveColors.light()),
    ('dark', WaveColors.dark()),
  ]) {
    group('$name palette', () {
      test('body text meets AA on surface', () {
        expect(
          contrast(c.textPrimary, c.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'textPrimary is '
              '${contrast(c.textPrimary, c.surface).toStringAsFixed(2)}:1',
        );
        expect(
          contrast(c.textSecondary, c.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'textSecondary is '
              '${contrast(c.textSecondary, c.surface).toStringAsFixed(2)}:1',
        );
      });

      test('accent label meets AA', () {
        expect(
          contrast(c.onAccent, c.accent),
          greaterThanOrEqualTo(4.5),
          reason: 'onAccent is '
              '${contrast(c.onAccent, c.accent).toStringAsFixed(2)}:1',
        );
        expect(
          contrast(c.onError, c.error),
          greaterThanOrEqualTo(4.5),
          reason: 'onError is '
              '${contrast(c.onError, c.error).toStringAsFixed(2)}:1',
        );
      });

      test('error text meets AA on surface', () {
        expect(
          contrast(c.error, c.surface),
          greaterThanOrEqualTo(4.5),
          reason: 'error is '
              '${contrast(c.error, c.surface).toStringAsFixed(2)}:1',
        );
      });

      test('input border meets 1.4.11 (3:1)', () {
        expect(
          contrast(c.borderInput, c.surface),
          greaterThanOrEqualTo(3.0),
          reason: 'borderInput is '
              '${contrast(c.borderInput, c.surface).toStringAsFixed(2)}:1',
        );
      });

      // Asserted per theme, because the two express elevation differently.
      // The previous single assertion encoded a dark-mode premise: in light
      // mode there is nothing above white, so demanding a tint difference
      // would force grey cards on a grey page — the flat outlined look
      // §3.1 exists to beat.
      test('elevation is expressible', () {
        if (name == 'dark') {
          // P8: dark elevation is lighter surface tint, not stronger shadow.
          expect(
            contrast(c.surfaceRaised, c.surface),
            greaterThan(1.15),
            reason: 'raised vs surface is '
                '${contrast(c.surfaceRaised, c.surface).toStringAsFixed(3)}:1',
          );
        } else {
          expect(c.shadowRaised, isNotEmpty);
          expect(c.shadowRaised.first.color.a, greaterThan(0));
          expect(c.shadowRaised.first.blurRadius, greaterThan(0));
        }
      });

      test('scrim foreground works over the scrim', () {
        expect(
          contrast(c.onScrim, c.scrim),
          greaterThanOrEqualTo(4.5),
          reason: 'onScrim is '
              '${contrast(c.onScrim, c.scrim).toStringAsFixed(2)}:1',
        );
      });
    });
  }

  group('trust tiers', () {
    for (final (name, c, t) in [
      ('light', WaveColors.light(), WaveTrustColors.light()),
      ('dark', WaveColors.dark(), WaveTrustColors.dark()),
    ]) {
      // Checked against both surfaces: badges sit on cards as often as on
      // the page background.
      test('$name tiers meet 3:1 on both surfaces', () {
        for (final (tier, color) in [
          ('bronze', t.bronze),
          ('silver', t.silver),
          ('gold', t.gold),
          ('platinum', t.platinum),
        ]) {
          for (final (where, bg) in [
            ('surface', c.surface),
            ('surfaceRaised', c.surfaceRaised),
          ]) {
            expect(
              contrast(color, bg),
              greaterThanOrEqualTo(3.0),
              reason: '$tier on $where is '
                  '${contrast(color, bg).toStringAsFixed(2)}:1',
            );
          }
        }
      });
    }
  });

  test('dark mode uses neither pure black nor pure white', () {
    final d = WaveColors.dark();
    expect(d.background, isNot(const Color(0xFF000000)));
    expect(d.surface, isNot(const Color(0xFF000000)));
    expect(d.textPrimary, isNot(const Color(0xFFFFFFFF)));
  });

  group('typography', () {
    for (final locale in [const Locale('en'), const Locale('ckb')]) {
      test('every Material slot carries a WAVE family (${locale.languageCode})',
          () {
        final theme = AppTheme.light(locale);
        final tt = theme.textTheme;
        final styles = <String, TextStyle?>{
          'displayLarge': tt.displayLarge,
          'displayMedium': tt.displayMedium,
          'displaySmall': tt.displaySmall,
          'headlineLarge': tt.headlineLarge,
          'headlineMedium': tt.headlineMedium,
          'headlineSmall': tt.headlineSmall,
          'titleLarge': tt.titleLarge,
          'titleMedium': tt.titleMedium,
          'titleSmall': tt.titleSmall,
          'bodyLarge': tt.bodyLarge,
          'bodyMedium': tt.bodyMedium,
          'bodySmall': tt.bodySmall,
          'labelLarge': tt.labelLarge,
          'labelMedium': tt.labelMedium,
          'labelSmall': tt.labelSmall,
        };
        for (final entry in styles.entries) {
          expect(
            entry.value?.fontFamily,
            anyOf(WaveFonts.arabic, WaveFonts.latin),
            reason: '${entry.key} fell back to Roboto',
          );
        }
      });

      test('tracking is zero everywhere (${locale.languageCode})', () {
        final t = WaveTextStyles.forLocale(
          locale,
          const Color(0xFF000000),
          const Color(0xFF000000),
        );
        for (final s in [t.display, t.headline, t.title, t.body, t.label]) {
          expect(s.letterSpacing, 0);
        }
      });

      test('Arabic body has room to breathe', () {
        final t = WaveTextStyles.forLocale(
          const Locale('ckb'),
          const Color(0xFF000000),
          const Color(0xFF000000),
        );
        expect(t.body.height, greaterThanOrEqualTo(1.6));
        expect(t.display.height, greaterThanOrEqualTo(1.3));
      });

      test('prices use tabular figures', () {
        final t = WaveTextStyles.forLocale(
          const Locale('en'),
          const Color(0xFF000000),
          const Color(0xFF000000),
        );
        expect(
          t.price.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
        expect(
          t.priceStruck.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      });
    }
  });

  group('motion', () {
    final m = WaveMotion.standard();

    // Guards M1: an unbounded curve on a FadeTransition asserts in Opacity.
    test('emphasized is bounded and safe on opacity', () {
      for (var i = 0; i <= 100; i++) {
        final v = m.emphasized.transform(i / 100);
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });

    test('the overshoot curve genuinely overshoots, but not much', () {
      var max = 0.0;
      for (var i = 0; i <= 100; i++) {
        max = math.max(max, m.emphasizedOvershoot.transform(i / 100));
      }
      expect(
        max,
        greaterThan(1.0),
        reason: 'peaks at $max — not a signature, just a curve',
      );
      expect(
        max,
        lessThan(1.15),
        reason: 'peaks at $max — more bounce than a marketplace wants',
      );
    });

    test('durations are ordered', () {
      expect(m.instant < m.fast, isTrue);
      expect(m.fast < m.base, isTrue);
      expect(m.base < m.slow, isTrue);
      expect(m.slow < m.deliberate, isTrue);
    });
  });

  group('extensions are registered', () {
    for (final (name, theme) in [
      ('light', AppTheme.light(const Locale('ckb'))),
      ('dark', AppTheme.dark(const Locale('ckb'))),
    ]) {
      // Each asserted separately: a single test aborts on the first failure,
      // which is why the WaveSpacing null masked the other five.
      test('$name registers WaveColors', () {
        expect(theme.extension<WaveColors>(), isNotNull);
      });
      test('$name registers WaveTrustColors', () {
        expect(theme.extension<WaveTrustColors>(), isNotNull);
      });
      test('$name registers WaveSurfaces', () {
        expect(theme.extension<WaveSurfaces>(), isNotNull);
      });
      test('$name registers WaveSpacing', () {
        expect(theme.extension<WaveSpacing>(), isNotNull);
      });
      test('$name registers WaveMotion', () {
        expect(theme.extension<WaveMotion>(), isNotNull);
      });
      test('$name registers WaveTextStyles', () {
        expect(theme.extension<WaveTextStyles>(), isNotNull);
      });

      test('$name neutralises surfaceTint', () {
        expect(theme.colorScheme.surfaceTint, Colors.transparent);
      });
    }
  });
}
