#!/usr/bin/env python3
"""Rebuilds the checked-in stub delegate from app_en.arb.

    python3 tool/sync_l10n_stub.py

`lib/l10n/generated/app_localizations.dart` is a placeholder that exists so a
fresh clone analyses before `flutter gen-l10n` has run. It is overwritten by
codegen, but while it is in the tree it has to expose every key in the template
ARB or the project stops compiling — and it has to expose them with the right
arity, or it compiles and then throws in whichever locale is unlucky.

Maintaining it by hand is a losing game: a key added to three ARB files and not
to the stub breaks the build, and a key added with the wrong arity breaks it in a
way that points at the call site rather than the cause. This derives it.
"""
import collections
import json
import re

ARB = 'lib/l10n/app_en.arb'
OUT = 'lib/l10n/generated/app_localizations.dart'
LOCALES = ['ar', 'ckb', 'en']

HEADER = """// PLACEHOLDER — overwritten by `flutter gen-l10n`.
//
// Checked in so a fresh clone analyses before the first codegen run. The real
// file is generated from lib/l10n/*.arb per l10n.yaml and is gitignored; this
// stub exists purely so `AppL10n` resolves on day one.
//
// Regenerate after adding keys:
//     python3 tool/sync_l10n_stub.py
//
// If you are reading this in a built project, codegen has not run. Fix with:
//     flutter gen-l10n
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppL10n {
  AppL10n(this.localeName);

  final String localeName;

  static AppL10n of(BuildContext context) =>
      Localizations.of<AppL10n>(context, AppL10n) ?? AppL10n('ar');

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
%(locales)s
  ];

"""

FOOTER = """}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) async => AppL10n(locale.languageCode);

  @override
  bool isSupported(Locale locale) =>
      <String>[%(quoted)s].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}
"""

# Placeholder types codegen infers when metadata is absent. A plural argument is
# always an int; anything else defaults to String.
PLURAL = re.compile(r'\{(\w+),\s*plural,')
PLACEHOLDER = re.compile(r'\{(\w+)[,}]')


def main():
    with open(ARB, encoding='utf-8') as fh:
        arb = json.load(fh, object_pairs_hook=collections.OrderedDict)

    lines = []
    for key, value in arb.items():
        if key.startswith('@'):
            continue

        meta = arb.get(f'@{key}', {})
        declared = meta.get('placeholders', {})

        # Order matters: codegen emits parameters in the order the placeholders
        # appear in the metadata, falling back to first-appearance order in the
        # message itself.
        if declared:
            names = list(declared)
        else:
            names = list(dict.fromkeys(PLACEHOLDER.findall(str(value))))
            # Plural sub-messages contain literal digits in `=0{...}` arms and
            # words inside them; only the plural variable itself is a parameter.
            plural = PLURAL.search(str(value))
            if plural:
                names = [plural.group(1)]

        if not names:
            lines.append(f"  String get {key} => '';")
            continue

        params = []
        for name in names:
            dart_type = declared.get(name, {}).get('type')
            if not dart_type:
                dart_type = 'int' if PLURAL.search(str(value)) else 'String'
            params.append(f'{dart_type} {name}')
        lines.append(f"  String {key}({', '.join(params)}) => '';")

    body = HEADER % {
        'locales': '\n'.join(f"    Locale('{l}')," for l in LOCALES)
    }
    body += '\n'.join(lines) + '\n'
    body += FOOTER % {'quoted': ', '.join(f"'{l}'" for l in LOCALES)}

    with open(OUT, 'w', encoding='utf-8') as fh:
        fh.write(body)

    print(f'stub regenerated: {len(lines)} keys')


if __name__ == '__main__':
    main()
