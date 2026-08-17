import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/theme/app_colors.dart';
import 'package:wave/core/theme/wave_colors.dart';
import 'package:wave/core/theme/wave_trust_colors.dart';

/// Locks in the §3.2 / §3.7 contrast claims by RECOMPUTING them, rather than
/// trusting the numbers written in the brief.
///
/// The point of this file: a token change that quietly breaks accessibility
/// fails CI instead of shipping. Someone "just nudging" a colour to look nicer
/// is exactly how a 4.6:1 error colour becomes a 3.1:1 error colour.
double _relativeLuminance(Color c) {
  double channel(double v) {
    final s = v; // already 0..1 in Flutter's Color component getters
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Light mode colour tokens meet their stated WCAG level', () {
    final c = WaveColors.light();

    void expectAtLeast(String name, Color fg, double min) {
      final ratio = contrastRatio(fg, c.background);
      expect(
        ratio,
        greaterThanOrEqualTo(min),
        reason: '$name measured ${ratio.toStringAsFixed(2)}:1 against '
            'background, below the required $min:1',
      );
    }

    test('text-primary is AAA (>= 7:1)', () =>
        expectAtLeast('text-primary', c.textPrimary, 7),);
    test('text-secondary is AAA (>= 7:1)', () =>
        expectAtLeast('text-secondary', c.textSecondary, 7),);
    test('primary is AAA (>= 7:1)', () =>
        expectAtLeast('primary', c.primary, 7),);
    test('accent-interactive is AA (>= 4.5:1)', () =>
        expectAtLeast('accent-interactive', c.accentInteractive, 4.5),);
    test('success is AA', () => expectAtLeast('success', c.success, 4.5));
    test('warning is AA', () => expectAtLeast('warning', c.warning, 4.5));
    test('error is AA', () => expectAtLeast('error', c.error, 4.5));
    test('info is AA', () => expectAtLeast('info', c.info, 4.5));

    test(
      'accent-glow is NOT text-safe — this is documented intent, not a bug',
      () {
        // If this ever passes, someone has changed accent-glow. Reconsider
        // whether accent-interactive is still needed before deleting the test.
        expect(
          contrastRatio(AppColorTokens.lightAccentGlow, c.background),
          lessThan(4.5),
        );
      },
    );
  });

  group('Dark mode colour tokens', () {
    final c = WaveColors.dark();

    void expectAtLeast(String name, Color fg, double min) {
      final ratio = contrastRatio(fg, c.background);
      expect(ratio, greaterThanOrEqualTo(min),
          reason: '$name measured ${ratio.toStringAsFixed(2)}:1',);
    }

    test('text-primary AAA', () => expectAtLeast('text-primary', c.textPrimary, 7));
    test('text-secondary AAA', () => expectAtLeast('text-secondary', c.textSecondary, 7));
    test('primary AA', () => expectAtLeast('primary', c.primary, 4.5));
    test('accent is text-safe in dark mode (AAA)', () =>
        expectAtLeast('accent', c.accentGlow, 7),);
    test('error AA', () => expectAtLeast('error', c.error, 4.5));
  });

  group('Trust badge tiers (§3.7)', () {
    test('all light-mode tiers clear AA against background and surface', () {
      final t = WaveTrustColors.light();
      final c = WaveColors.light();
      for (final (name, colour) in [
        ('bronze', t.bronze),
        ('silver', t.silver),
        ('gold', t.gold),
        ('platinum', t.platinum),
      ]) {
        expect(contrastRatio(colour, c.background), greaterThanOrEqualTo(4.5),
            reason: '$name against background',);
        expect(contrastRatio(colour, c.surface), greaterThanOrEqualTo(4.5),
            reason: '$name against surface',);
      }
    });

    test('all dark-mode tiers clear AA', () {
      final t = WaveTrustColors.dark();
      final c = WaveColors.dark();
      for (final colour in [t.bronze, t.silver, t.gold, t.platinum]) {
        expect(contrastRatio(colour, c.background), greaterThanOrEqualTo(4.5));
        expect(contrastRatio(colour, c.surface), greaterThanOrEqualTo(4.5));
      }
    });

    test(
      'gold is distinguishable from the warning semantic colour',
      () {
        // Gold and warning necessarily share the amber family. This does not
        // assert they are far apart — they cannot be. It asserts they are not
        // IDENTICAL, which would make the icon+label rule the only thing
        // separating "Gold Trusted" from "Low stock".
        final t = WaveTrustColors.light();
        final c = WaveColors.light();
        expect(t.gold, isNot(equals(c.warning)));
      },
    );
  });
}
