import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the ARB set against the ways localization rots invisibly.
///
/// None of these failures shows up in review. A key missing from one locale
/// falls back to English, so the app looks correct to an English-speaking
/// developer and is half-translated for exactly the people it was translated
/// for — who are also the people least likely to be in the room when it ships.
void main() {
  const locales = ['en', 'ckb', 'ar'];

  Map<String, dynamic> load(String locale) => json.decode(
        File('lib/l10n/app_$locale.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

  Set<String> keysOf(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  /// True if a value has no translatable words outside its placeholders.
  ///
  /// `'{quantity} × {title}'` is layout, not language: identical in all three
  /// locales because there is nothing in it to translate. Both the
  /// "differs from English" and "contains Arabic script" tests below would
  /// otherwise flag every such key.
  ///
  /// Derived from the value rather than listed by hand, and that distinction is
  /// the whole point. A hand-maintained exception set is what hid `buyNow`,
  /// whose English value held Kurdish text: the test failed correctly and the
  /// key was added to an allow-list. This predicate cannot be misused the same
  /// way, because any letter outside a placeholder makes a string translatable
  /// and no amount of listing changes that.
  bool isFormatOnly(String value) => !RegExp(r'[^\W\d_]', unicode: true)
      .hasMatch(value.replaceAll(RegExp(r'\{[^{}]*\}'), ''));

  late Map<String, Map<String, dynamic>> arbs;

  setUpAll(() {
    arbs = {for (final l in locales) l: load(l)};
  });

  group('ARB integrity across all three launch locales', () {
    test('every locale defines exactly the same keys', () {
      final source = keysOf(arbs['en']!);

      for (final locale in locales.where((l) => l != 'en')) {
        final theirs = keysOf(arbs[locale]!);
        expect(
          source.difference(theirs),
          isEmpty,
          reason: '$locale is missing keys; they would silently fall back to '
              'English',
        );
        expect(
          theirs.difference(source),
          isEmpty,
          reason: '$locale has keys with no English source, so they are '
              'unreachable',
        );
      }
    });

    test('no translation is empty', () {
      // An empty string renders as nothing, which reads as a layout bug rather
      // than a missing translation.
      for (final locale in locales) {
        for (final entry in arbs[locale]!.entries) {
          if (entry.key.startsWith('@')) continue;
          expect(
            (entry.value as String).trim(),
            isNotEmpty,
            reason: '${entry.key} is empty in $locale',
          );
        }
      }
    });

    test('no translation is identical to its English source', () {
      // Allowed only for the brand name and genuine loanwords. Anything else
      // matching exactly is an untranslated placeholder someone forgot.
      //
      // `buyNow` used to be listed here. It was not a loanword: the English
      // value held the Kurdish translation, so en and ckb matched exactly and
      // this test failed honestly — and the failure was silenced by adding the
      // key to this set rather than fixing the value. An exemption added to
      // make a test pass disarms the test for every future regression too, so
      // the entry is gone and the value is fixed.
      const allowed = {'appName', 'reels'};

      for (final locale in locales.where((l) => l != 'en')) {
        final suspicious = <String>[];
        for (final key in keysOf(arbs['en']!)) {
          if (allowed.contains(key)) continue;
          if (isFormatOnly(arbs['en']![key] as String)) continue;
          if (arbs['en']![key] == arbs[locale]![key]) suspicious.add(key);
        }
        expect(
          suspicious,
          isEmpty,
          reason: 'untranslated in $locale: ${suspicious.join(', ')}',
        );
      }
    });

    test('placeholders match across every locale', () {
      // A placeholder present in one locale and absent in another throws at
      // runtime, in that locale only — the hardest kind of crash to notice from
      // an English-speaking desk.
      final pattern = RegExp(r'\{(\w+)[,}]');

      for (final key in keysOf(arbs['en']!)) {
        final expected = pattern
            .allMatches(arbs['en']![key] as String)
            .map((m) => m.group(1))
            .toSet();

        for (final locale in locales.where((l) => l != 'en')) {
          final actual = pattern
              .allMatches(arbs[locale]![key] as String)
              .map((m) => m.group(1))
              .toSet();
          expect(
            actual,
            expected,
            reason: 'placeholder mismatch: $key ($locale)',
          );
        }
      }
    });

    test('every plural declares its placeholder metadata', () {
      for (final key in keysOf(arbs['en']!)) {
        final value = arbs['en']![key] as String;
        if (!value.contains(', plural,')) continue;
        expect(
          arbs['en']!['@$key'],
          isNotNull,
          reason: '"$key" uses a plural with no @$key metadata, so codegen '
              'cannot type its argument',
        );
      }
    });

    test('both RTL locales actually contain Arabic script', () {
      // The check the others cannot make. A Latin-script value in ar or ckb
      // passes every test above — identical key sets, non-empty, different from
      // English — and is still an untranslated leftover or a paste from the
      // wrong column.
      final arabicScript = RegExp(r'[\u0600-\u06FF\u0750-\u077F]');

      // Brand and product names stay in Latin script by design: "ZainCash" is
      // ZainCash in every language, and translating it would make the option
      // unrecognisable next to the provider's own branding.
      // `buyNow` is deliberately absent: both RTL values are real translations
      // and must stay that way. It was listed here only to accommodate the
      // English value holding Kurdish text.
      const latinByDesign = {
        'appName',
        'reels',
        'continueWithGoogle',
        'continueWithApple',
        'railBankCardBody',
        'receiptDocTitle',
      };

      for (final locale in ['ar', 'ckb']) {
        for (final key in keysOf(arbs[locale]!)) {
          if (latinByDesign.contains(key)) continue;
          if (isFormatOnly(arbs['en']![key] as String)) continue;
          final value = (arbs[locale]![key] as String).trim();
          if (value.isEmpty) continue;
          expect(
            arabicScript.hasMatch(value),
            isTrue,
            reason: '$key in $locale contains no Arabic script — likely '
                'untranslated',
          );
        }
      }
    });
  });
}
