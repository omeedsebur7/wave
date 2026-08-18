import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/l10n/wave_localizations.dart';
import 'package:wave/core/theme/app_theme.dart';

/// Wraps a widget in the real WAVE theme so a widget test exercises the same
/// tokens production does.
///
/// Tests that build their own bare MaterialApp silently opt out of every
/// ThemeExtension, which means a widget reading `context.waveColors` throws —
/// or worse, a test passes against a theme that does not exist in the app.
///
/// It uses [WaveLocalizations.delegates], the same list app.dart passes, for the
/// same reason. Two consequences worth knowing:
///
///  - Without AppL10n.delegate, every widget calling `context.l10n` throws
///    "Null check operator used on a null value" from AppL10n.of — which reads
///    as a widget bug and is a harness bug.
///  - Without the ckb fallbacks, a Locale('ckb') test logs "not supported by all
///    of its localization delegates" and resolves LTR, so the RTL tests below
///    were only RTL because they passed textDirection by hand.
extension PumpApp on WidgetTester {
  Future<void> pumpWave(
    Widget widget, {
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
    TextDirection? textDirection,
    double textScale = 1,
  }) {
    return pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? AppTheme.light(locale)
            : AppTheme.dark(locale),
        locale: locale,
        localizationsDelegates: WaveLocalizations.delegates,
        supportedLocales: WaveLocalizations.supported,
        home: Directionality(
          // Resolved from the locale rather than hardcoded per call site, and
          // via WaveLocalizations.isRtl so a third RTL locale does not have to
          // be remembered in a ternary here as well as in the app.
          //
          // Still overridable: a test that wants to prove a widget survives the
          // WRONG direction for its locale is a legitimate thing to write.
          textDirection: textDirection ??
              (WaveLocalizations.isRtl(locale)
                  ? TextDirection.rtl
                  : TextDirection.ltr),
          child: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: Center(
                child: widget,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
