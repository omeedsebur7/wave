import 'package:flutter/material.dart';
import 'package:wave/core/theme/wave_colors.dart' show WaveColors;
import 'package:wave/core/theme/wave_trust_colors.dart' show WaveTrustColors;

/// Raw colour tokens from the WAVE brief §3.2 and §3.7.
///
/// These are the ONLY places a hex literal is allowed to live. Every widget
/// reads colour through [WaveColors] / [WaveTrustColors] ThemeExtensions —
/// never from this class directly, and never from an ad-hoc `Color(0xFF...)`.
/// Contrast ratios in the comments were verified against the WCAG 2.1
/// relative-luminance formula; see test/golden/design_tokens_test.dart, which
/// recomputes them so the numbers can't silently rot.
abstract final class AppColorTokens {
  // ─── Light mode ────────────────────────────────────────────────────────
  static const lightBackground = Color(0xFFFAFAFA); // Clean Pearl White
  static const lightSurface = Color(0xFFFFFFFF); // Pure White
  static const lightTextPrimary = Color(0xFF0F172A); // 17.1:1 AAA
  static const lightTextSecondary = Color(0xFF475569); // 7.3:1  AAA
  static const lightPrimary = Color(0xFF4338CA); // 7.6:1  AAA

  /// Cyan Hologram. DECORATIVE ONLY — 2.3:1, fails WCAG at every level.
  /// Glow, gradients and 3D lighting. Never behind text, an icon, or a tap
  /// target; use [lightAccentInteractive] for those.
  static const lightAccentGlow = Color(0xFF06B6D4);
  static const lightAccentInteractive = Color(0xFF0E7490); // 5.1:1 AA

  static const lightSuccess = Color(0xFF047857); // 5.3:1 AA
  static const lightWarning = Color(0xFFB45309); // 4.8:1 AA
  static const lightError = Color(0xFFDC2626); // 4.6:1 AA
  static const lightInfo = Color(0xFF0369A1); // 5.7:1 AA
  static const lightBorder = Color(0xFFE2E8F0); // non-text UI

  // ─── Dark mode ─────────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF0B0F19); // Deep Space Navy
  static const darkSurface = Color(0xFF111827); // Dark Obsidian
  static const darkTextPrimary = Color(0xFFF8FAFC); // 18.3:1 AAA
  static const darkTextSecondary = Color(0xFF94A3B8); // 7.5:1  AAA
  static const darkPrimary = Color(0xFF818CF8); // 6.4:1  AA

  /// Bright Teal — unlike its light-mode counterpart this one is text-safe
  /// (10.3:1 AAA), so dark mode uses a single accent for glow AND interaction.
  static const darkAccent = Color(0xFF2DD4BF);

  static const darkSuccess = Color(0xFF34D399); // 10.0:1 AAA
  static const darkWarning = Color(0xFFFBBF24); // 11.5:1 AAA
  static const darkError = Color(0xFFF87171); // 6.9:1  AA
  static const darkInfo = Color(0xFF38BDF8); // 8.9:1  AAA
  static const darkBorder = Color(0xFF1E293B); // non-text UI

  // ─── Trust badge tiers (§3.7) ──────────────────────────────────────────
  // Kept separate from the semantic colours above on purpose: a tier badge
  // and a stock/payment warning mean different things.
  static const lightTrustBronze = Color(0xFF92400E); // 6.79 / 7.09 AAA
  static const lightTrustSilver = Color(0xFF52606D); // 6.19 / 6.46 AA
  static const lightTrustGold = Color(0xFF8A6D1B); // 4.70 / 4.90 AA
  static const lightTrustPlatinum = Color(0xFF6D28D9); // 6.81 / 7.10 AAA

  static const darkTrustBronze = Color(0xFFE3A867); // 9.18 / 8.50 AAA
  static const darkTrustSilver = Color(0xFFB8C4D1); // 10.81 / 10.01 AAA
  static const darkTrustGold = Color(0xFFCA8A04); // 6.52 / 6.04 AA
  static const darkTrustPlatinum = Color(0xFFA78BFA); // 7.04 / 6.52 AAA
}
