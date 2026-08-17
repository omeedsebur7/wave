import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's chosen language.
///
/// Stored locally rather than on the profile, because language is a property of
/// the device someone is reading on, not of their account — and because it has
/// to be readable before sign-in, on the very first screen.
///
/// A null value means "follow the system", which is the right default: a phone
/// set to Arabic should open in Arabic without anyone choosing anything. The
/// picker exists for when that default is wrong — a phone sold with an English
/// system locale to someone who reads Kurdish, which is common here.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs) {
    final saved = _prefs.getString(_key);
    if (saved != null) _locale = Locale(saved);
  }

  static const _key = 'app_locale';

  final SharedPreferences _prefs;
  Locale? _locale;

  /// Null means follow the system.
  Locale? get locale => _locale;

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    if (locale == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, locale.languageCode);
    }
    notifyListeners();
  }

  /// The languages offered, each written in its own script.
  ///
  /// Never translated into the current language — someone looking for Kurdish
  /// is looking for "کوردیی ناوەندی", and showing them "Kurdish" rendered in
  /// Arabic is no help if Arabic is the language they cannot read. That person
  /// is exactly who this list exists for.
  static const options = <({Locale? locale, String label})>[
    (locale: null, label: 'System default'),
    (locale: Locale('ar'), label: 'العربية'),
    (locale: Locale('ckb'), label: 'کوردیی ناوەندی'),
    (locale: Locale('en'), label: 'English'),
  ];
}
