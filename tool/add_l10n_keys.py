#!/usr/bin/env python3
"""Adds localization keys to all three ARB files at once.

    python3 tool/add_l10n_keys.py keys.json

Where keys.json is:

    [
      {"key": "someKey",
       "en": "English", "ckb": "کوردی", "ar": "عربي",
       "placeholders": {"count": "int"}}
    ]

Adding a key by hand means editing three files in three scripts and then the
stub delegate, and the failure mode is silent: a key missing from ckb falls back
to English, which looks correct to whoever added it. Doing all four in one
operation is the only way that stays true over time.

Refuses to overwrite an existing key. Reusing a key with a different shape is
how `setDeliveryLocation` broke every one of its call sites at once.
"""
import collections
import json
import sys

LOCALES = ['en', 'ckb', 'ar']
ARB = 'lib/l10n/app_{}.arb'


def load(locale):
    with open(ARB.format(locale), encoding='utf-8') as fh:
        return json.load(fh, object_pairs_hook=collections.OrderedDict)


def save(locale, data):
    with open(ARB.format(locale), 'w', encoding='utf-8') as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.write('\n')


def main(path):
    with open(path, encoding='utf-8') as fh:
        additions = json.load(fh)

    arbs = {locale: load(locale) for locale in LOCALES}

    for entry in additions:
        key = entry['key']
        for locale in LOCALES:
            if key in arbs[locale]:
                sys.exit(
                    f'{key} already exists in {locale} — reusing a key with a '
                    'different shape silently changes every existing call site'
                )

    for entry in additions:
        key = entry['key']
        for locale in LOCALES:
            arbs[locale][key] = entry[locale]
        # Metadata lives only in the template file, which is where codegen
        # reads placeholder types from.
        if entry.get('placeholders'):
            arbs['en'][f'@{key}'] = collections.OrderedDict(
                placeholders=collections.OrderedDict(
                    (name, {'type': dart_type})
                    for name, dart_type in entry['placeholders'].items()
                )
            )

    for locale in LOCALES:
        save(locale, arbs[locale])

    print(f'added {len(additions)} keys to {", ".join(LOCALES)}')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
