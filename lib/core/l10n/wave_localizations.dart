import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wave/l10n/generated/app_localizations.dart';

abstract final class WaveLocalizations {
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    AppLocalizations.delegate,
    _CkbMaterialLocalizationsDelegate(),
    _CkbWidgetsLocalizationsDelegate(),
    _CkbCupertinoLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supported = [
    Locale('ar'),
    Locale('ckb'),
    Locale('en'),
  ];

  static const Locale fallback = Locale('ar');

  static bool isRtl(Locale locale) =>
      locale.languageCode == 'ar' || locale.languageCode == 'ckb';
}

class _CkbMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _CkbMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) =>
      false;
}

class _CkbWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _CkbWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<WidgetsLocalizations> old,
  ) =>
      false;
}

class _CkbCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CkbCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ckb';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('ar'));

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<CupertinoLocalizations> old,
  ) =>
      false;
}
