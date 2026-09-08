import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave/core/l10n/wave_localizations.dart';
import 'package:wave/core/theme/app_theme.dart';

class WaveTestApp extends StatelessWidget {
  const WaveTestApp({
    required this.child,
    this.locale = const Locale('ckb'),
    this.brightness = Brightness.light,
    this.textScale = 1.0,
    super.key,
  });

  final Widget child;
  final Locale locale;
  final Brightness brightness;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: WaveLocalizations.delegates,
      supportedLocales: WaveLocalizations.supported,
      locale: locale,
      themeMode: brightness == Brightness.light ? ThemeMode.light : ThemeMode.dark,
      
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),

      builder: (context, childWidget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: childWidget!,
        );
      },
      home: Scaffold(
        body: child,
      ),
    );
  }
}

extension WaveTesterExtension on WidgetTester {
  Future<void> pumpWave(
    Widget widget, {
    Locale locale = const Locale('ckb'),
    Brightness brightness = Brightness.light,
    double textScale = 1.0,
  }) async {
    await pumpWidget(
      WaveTestApp(
        locale: locale,
        brightness: brightness,
        textScale: textScale,
        child: widget,
      ),
    );
    await pumpAndSettle(); 
  }
}
