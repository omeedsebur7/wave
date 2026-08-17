#!/usr/bin/env python3
"""Static consistency checks for the WAVE project.

Run before packaging or opening a PR:

    python3 tool/check_project.py

This is not a substitute for `flutter analyze`. It catches a different class of
problem — the cross-file kind that compiles fine and is wrong anyway: a callable
with no handler, a query with no index, a collection with no Security Rule, a
translation key missing from one locale, a field written and never read.

The first check is deliberately file EXISTENCE. Every other check reads files it
assumes are present, so when work goes missing the rest pass vacuously — the code
referencing the missing file went with it. Asserting presence first is what makes
the remaining results mean anything, and this script exits immediately if that
check fails rather than printing a page of misleading passes.
"""
import collections
import json
import os
import re
import sys

# ── Documented exceptions ────────────────────────────────────────────────────
# Each of these is a decision, explained where it is made. Listed here so the
# check keeps flagging everything that is not one of them.

# Screens that stay in one language on purpose.
UNLOCALIZED_BY_DESIGN = {
    # An internal tool for a small moderation team. Translating it into three
    # languages would be cost with no reader.
    'features/moderation/presentation/pages/moderation_queue_page.dart',
    # Language names are written in their own scripts and must never be
    # translated — someone looking for Kurdish is looking for "کوردیی ناوەندی",
    # and "Kurdish" rendered in Arabic helps nobody who cannot read Arabic.
    'features/settings/presentation/pages/language_page.dart',
    'core/settings/locale_controller.dart',
}

# Individual strings that are multilingual literals by design.
STRING_EXCEPTIONS = {
    'Language · اللغة · زمان',  # findable whichever of the three you read

    # Payment provider brand names. "ZainCash" is ZainCash in every language,
    # and translating it would make the option unrecognisable next to the
    # provider's own branding — which is the one thing a payment option cannot
    # afford to be. Defined on PaymentRail.brandName; see the note there.
    'ZainCash',
    'AsiaHawala',
    'Qi Card',

    # A dialling-format mask, not a sentence. The digits and the country code
    # are the same in every language, and translating "XXX" into Arabic-Indic
    # placeholder digits would make the field harder to read, not easier —
    # people type Western digits into phone fields on these keyboards.
    '+964 7XX XXX XXXX',

    # OpenStreetMap's attribution. The ODbL expects the credit to be
    # recognisable as the project's name, so it is rendered LTR in all three
    # locales. See the note at OsmAttribution.
    '© OpenStreetMap',

    # A release-blocking warning drawn only when the app is pointed at donated
    # tile infrastructure. Addressed to whoever is building the app, not to a
    # user, and it must not be shipped at all — translating it would imply it
    # can be.
    'Using shared OSM tiles — set TILE_URL before release',
}

# Keys that stay in Latin script in ar/ckb: brand and product names. "ZainCash"
# is ZainCash in every language.
#
# `buyNow` is deliberately not here. It was, and it was covering for a bug: the
# English value contained the Kurdish translation, so en and ckb matched and both
# this set and SAME_AS_ENGLISH_OK were widened to keep the checks green. That is
# the worst possible response to a true failure, because it also silences every
# future one.
LATIN_BY_DESIGN = {
    'appName', 'reels', 'continueWithGoogle', 'continueWithApple',
    'railBankCardBody', 'receiptDocTitle',
}

# Translations allowed to match their English source.
SAME_AS_ENGLISH_OK = {'appName', 'reels'}

# Collections whose rules live at a nested path the first-segment scan misses.
RULE_PATH_EXCEPTIONS = {'counters_likes', 'counters_views', 'blocked'}

# Thrown-and-caught exception messages that no user can ever see, so they need
# no FailureReason.
#
# Listed individually rather than exempting `Exception` as a class, because the
# distinction is whether the throw ESCAPES — and that has to be checked by
# reading the code, not inferred from the type name. Each entry below was traced
# to the catch that swallows it:
#
#   'Bunny rejected the upload' — thrown inside `_uploadToBunny`, caught by the
#   bare `catch (e)` in `publish` two frames up, which returns a ServerFailure
#   carrying FailureReason.uploadFailed. The status code is interpolated for the
#   log; the user gets the translated "Upload failed. Try again."
EXCEPTION_MESSAGES_NOT_SURFACED = {
    'Bunny rejected the upload (${response.statusCode})',
}

LOCALES = ['en', 'ckb', 'ar']

# Placeholder text with no words in it — `'{quantity} × {title}'`,
# `'{title} ({count})'`. These are identical in all three locales because there
# is nothing in them to translate, and both the "not identical to English" and
# "contains Arabic script" checks would otherwise flag every one.
#
# DERIVED from the value rather than listed by hand, which matters more than it
# looks. A hand-maintained exception set is exactly what concealed `buyNow`: the
# English value held Kurdish text, the check failed honestly, and the key was
# added to an allow-list. This predicate cannot be abused that way, because a
# string containing any letter outside a placeholder is not format-only and no
# amount of listing makes it so.
def is_format_only(value):
    """True if the value has no translatable words outside its placeholders."""
    return not re.search(r'[^\W\d_]', re.sub(r'\{[^{}]*\}', '', str(value)))

REQUIRED_FILES = [
    'lib/l10n/app_en.arb', 'lib/l10n/app_ckb.arb', 'lib/l10n/app_ar.arb',
    'lib/l10n/generated/app_localizations.dart',
    'lib/core/settings/locale_controller.dart',
    'lib/core/services/write_throttle.dart',
    'lib/features/settings/presentation/pages/language_page.dart',
    'lib/features/auth/presentation/pages/account_recovery_page.dart',
    'lib/features/moderation/domain/entities/report.dart',
    'lib/features/moderation/data/moderation_repository.dart',
    'lib/features/moderation/presentation/pages/moderation_queue_page.dart',
    'lib/features/moderation/presentation/pages/suspended_page.dart',
    'functions/src/moderation/resolveReport.ts',
    'functions/src/common/otpGuard.ts',
    'functions/src/common/onPhoneLinked.ts',
    'functions/src/orders/placeOrder.ts',
    'functions/src/domain/promoCode.ts',
    'functions/src/promo/validatePromoCode.ts',
    'lib/features/cart/data/promo_repository.dart',
    'integration_test/helpers/fake_bunny.dart',
    'integration_test/helpers/seed.dart',
    'test/core/l10n_test.dart',
    'test/core/block_list_test.dart',
    'lib/core/services/block_list.dart',
    'lib/core/widgets/offline_banner.dart',
    'lib/core/services/startup_trace.dart',
    'functions/src/maintenance/retention.ts',
    'functions/src/privacy/accountDeletion.ts',
    'functions/test/retention.test.ts',
    'lib/features/cart/data/cart_store.dart',
    'test/features/cart_store_test.dart',
    'firestore.rules', 'firestore.indexes.json', 'storage.rules', 'README.md',
]

results = []


def check(name, ok, detail=''):
    results.append((name, bool(ok), detail))


def checking(name):
    """Wraps a check so an exception inside it becomes a FAIL, not a crash.

    Results are printed at the end, so an uncaught exception anywhere used to
    discard every result gathered so far — including the checks that had already
    failed and were the reason someone ran this. A missing translation key raised
    KeyError three checks after the one that had correctly detected it, and the
    output was a traceback with no indication which invariant was broken.

    A tool that dies on bad input is a tool people stop trusting on exactly the
    inputs it exists for.
    """
    class _Guard:
        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, _tb):
            if exc_type is None:
                return False
            check(name, False, f'{exc_type.__name__}: {exc}')
            return True  # swallowed; the FAIL carries the information

    return _Guard()


def strip_comments(src):
    out, i, n = [], 0, len(src)
    while i < n:
        if src[i] == '/' and i + 1 < n and src[i + 1] == '/':
            while i < n and src[i] != '\n':
                i += 1
            continue
        if src[i] == '/' and i + 1 < n and src[i + 1] == '*':
            i += 2
            while i + 1 < n and not (src[i] == '*' and src[i + 1] == '/'):
                i += 1
            i += 2
            continue
        out.append(src[i])
        i += 1
    return ''.join(out)


def strip_ts(src):
    """Strings, template literals, regex literals and comments removed.

    NOT SUITABLE FOR COUNTING IDENTIFIER USAGES. Template literals are blanked
    wholesale, so a variable referenced only as `${host}` inside one appears
    unused. A `noUnusedLocals` sweep built on this reported seven false
    positives for exactly that reason — every one was genuinely used inside a
    template literal, and "fixing" them would have deleted working code. Use
    the raw source for usage counts; use this only for structural questions
    like delimiter balance, where a string's contents are noise.

    Regex literals matter: `[^)]` inside one is a lone closing paren as far as a
    naive count is concerned, and reporting that as unbalanced code is a false
    positive that trains people to ignore the check. Distinguishing a regex from
    a division sign needs the preceding token, which is why this looks at what
    came before the slash.
    """
    out, i, n = [], 0, len(src)
    prev_significant = ''
    while i < n:
        c = src[i]
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            while i < n and src[i] != '\n':
                i += 1
            continue
        if c == '/' and i + 1 < n and src[i + 1] == '*':
            i += 2
            while i + 1 < n and not (src[i] == '*' and src[i + 1] == '/'):
                i += 1
            i += 2
            continue
        # A slash starts a regex only where a value cannot already have ended.
        if c == '/' and prev_significant in ('', '(', ',', '=', ':', '[', '!',
                                             '&', '|', '?', '{', '}', ';',
                                             '+', '-', '*', '~', '^', '<',
                                             '>', '%'):
            i += 1
            in_class = False
            while i < n:
                if src[i] == '\\':
                    i += 2
                    continue
                if src[i] == '[':
                    in_class = True
                elif src[i] == ']':
                    in_class = False
                elif src[i] == '/' and not in_class:
                    i += 1
                    break
                elif src[i] == '\n':
                    break
                i += 1
            out.append('R')
            prev_significant = 'R'
            continue
        if c in ('"', "'", '`'):
            quote = c
            i += 1
            while i < n:
                if src[i] == '\\':
                    i += 2
                    continue
                if quote == '`' and src[i] == '$' and i + 1 < n and src[i + 1] == '{':
                    depth = 0
                    i += 1
                    while i < n:
                        if src[i] == '{':
                            depth += 1
                        elif src[i] == '}':
                            depth -= 1
                            if depth == 0:
                                i += 1
                                break
                        i += 1
                    continue
                if src[i] == quote:
                    i += 1
                    break
                i += 1
            out.append('S')
            prev_significant = 'S'
            continue
        out.append(c)
        if not c.isspace():
            prev_significant = c
        i += 1
    code = ''.join(out)

    # Generic type arguments are removed, and `<`/`>` are then treated as
    # ordinary characters.
    #
    # They are ambiguous in TypeScript between generics and comparison, and
    # telling them apart needs a parser. Treating them as brackets made every
    # `items.length > 1` unbalance an argument count; ignoring them entirely made
    # `Map<string, number>` hide a comma. Stripping the shape that is
    # unambiguously a generic — an identifier followed by angle brackets holding
    # no operators — handles both.
    ts_generic = re.compile(r'(?<=[\w])<[^<>()=;{}]*>')
    for _ in range(6):
        code, replaced = ts_generic.subn('', code)
        if replaced == 0:
            break
    return code


def strip_dart(src):
    """Comments and string literals removed, so delimiter counting is sound."""
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c == '/' and i + 1 < n and src[i + 1] == '/':
            while i < n and src[i] != '\n':
                i += 1
            continue
        if c == '/' and i + 1 < n and src[i + 1] == '*':
            i += 2
            while i + 1 < n and not (src[i] == '*' and src[i + 1] == '/'):
                i += 1
            i += 2
            continue
        if c in ('"', "'"):
            q, triple = c, src[i:i + 3] == c * 3
            i += 3 if triple else 1
            while i < n:
                if src[i] == '\\':
                    i += 2
                    continue
                if src[i] == '$' and i + 1 < n and src[i + 1] == '{':
                    depth = 0
                    i += 1
                    while i < n:
                        if src[i] == '{':
                            depth += 1
                        elif src[i] == '}':
                            depth -= 1
                            if depth == 0:
                                i += 1
                                break
                        i += 1
                    continue
                if triple and src[i:i + 3] == q * 3:
                    i += 3
                    break
                if not triple and src[i] == q:
                    i += 1
                    break
                i += 1
            out.append('""')
            continue
        out.append(c)
        i += 1
    return ''.join(out)


# ── 0. Existence, first and blocking ─────────────────────────────────────────
absent = [f for f in REQUIRED_FILES if not os.path.exists(f)]
if absent:
    print('MISSING FILES — every other check would pass vacuously:\n')
    for f in absent:
        print(f'  {f}')
    sys.exit(1)
check('Every expected file is on disk', True)

dart = {}
for tree in ('lib', 'test', 'integration_test'):
    for root, _, files in os.walk(tree):
        for f in files:
            if f.endswith('.dart'):
                p = os.path.join(root, f)
                dart[p] = open(p).read()

ts_all = ''.join(
    open(os.path.join(r, f)).read()
    for r, _, fs in os.walk('functions/src') for f in fs if f.endswith('.ts')
)
index_ts = open('functions/src/index.ts').read()
rules = open('firestore.rules').read()
readme = open('README.md').read()

# Comment-free view. The rules file is heavily commented by design, and a naive
# substring window can land entirely inside an explanation and miss the rule it
# is explaining — which is exactly what happened to the promo check.
rules_code = '\n'.join(
    line.split('//')[0] for line in rules.split('\n')
)
lib_code = '\n'.join(
    strip_comments(s) for p, s in dart.items() if p.startswith('lib')
)

# ── Dart structure ───────────────────────────────────────────────────────────
bad = [f'{p} -> {i}' for p, s in dart.items()
       for i in re.findall(r"import 'package:wave/(.*?)'", s)
       if not os.path.exists('lib/' + i)]
check('Dart imports resolve', not bad, bad[:3])

bad = sorted({p for p, s in dart.items()
              for o, c in (('{', '}'), ('(', ')'), ('[', ']'))
              if strip_dart(s).count(o) != strip_dart(s).count(c)})
check('Dart delimiters balanced', not bad, bad[:3])

defined = collections.defaultdict(list)
for p, s in dart.items():
    if not p.startswith('lib'):
        continue
    for m in re.finditer(
        r'^(?:abstract |sealed |final |base |abstract final )*'
        r'(?:class|enum|mixin|extension)\s+([A-Z]\w*)', s, re.M
    ):
        defined[m.group(1)].append(p)
dupes = [n for n, ps in defined.items() if len(ps) > 1]
check('No duplicate top-level types', not dupes, dupes)

di = open('lib/app/di/injector.dart').read()
bad = []
for m in re.finditer(r'\(\) => (\w+)\(((?:getIt\(\),?\s*)*)\)', di):
    cls, args = m.group(1), m.group(2).count('getIt()')
    for path in defined.get(cls, []):
        ctor = re.search(rf'{cls}\(\s*((?:this\.\w+,?\s*)+)\)',
                         open(path).read())
        if ctor and len(re.findall(r'this\.\w+', ctor.group(1))) != args:
            bad.append(f'{cls}: DI passes {args}')
check('DI arity matches constructors', not bad, bad)

routes = open('lib/app/router/routes.dart').read()
names = (set(re.findall(r'static const (\w+) =', routes))
         | set(re.findall(r'static String (\w+)\(', routes)))
bad = [u for u in set(re.findall(r'Routes\.(\w+)', lib_code)) if u not in names]
check('Every Routes reference is defined', not bad, bad)

events = {m.group(1) for p, s in dart.items() if p.endswith('_bloc.dart')
          for m in re.finditer(r'class (\w+) extends \w+Event\b',
                               strip_comments(s))
          if not m.group(1).startswith('_')}
bad = [e for e in events
       if not re.search(rf'add\(\s*(?:const\s+)?{e}\b', lib_code)]
check('Every BLoC event is dispatched', not bad, bad)

# ── Localization ─────────────────────────────────────────────────────────────
arbs = {l: json.load(open(f'lib/l10n/app_{l}.arb')) for l in LOCALES}


def keys_of(arb):
    return {k for k in arb if not k.startswith('@')}


source = keys_of(arbs['en'])

mismatched = {l: sorted(source ^ keys_of(arbs[l]))[:3]
              for l in LOCALES[1:] if keys_of(arbs[l]) != source}
check('All locales share identical keys', not mismatched, mismatched)

with checking('No empty translations'):
    check('No empty translations',
          all(str(arbs[l][k]).strip()
              for l in LOCALES for k in keys_of(arbs[l])))

# `.get(k)` rather than `[k]`.
#
# A key missing from one locale used to raise KeyError here, and the checker died
# with a traceback instead of reporting the mismatch the check above had already
# detected. A crash is technically a red build, but it hides which check failed
# and reads as a broken tool rather than a broken translation.
same = {l: [k for k in source
            if k not in SAME_AS_ENGLISH_OK
            and not is_format_only(arbs['en'][k])
            and arbs[l].get(k) is not None
            and arbs['en'][k] == arbs[l][k]]
        for l in LOCALES[1:]}
check('No untranslated values', not any(same.values()),
      {l: v[:3] for l, v in same.items() if v})

ph = re.compile(r'\{(\w+)[,}]')
bad = sorted({k for k in source for l in LOCALES[1:]
              if arbs[l].get(k) is not None
              and set(ph.findall(str(arbs[l][k])))
              != set(ph.findall(str(arbs['en'][k])))})
check('Placeholders aligned across locales', not bad, bad[:3])

script = re.compile(r'[\u0600-\u06FF\u0750-\u077F]')
bad = [f'{l}:{k}' for l in ('ar', 'ckb') for k in keys_of(arbs[l])
       if k not in LATIN_BY_DESIGN
       and not is_format_only(arbs['en'].get(k, ''))
       and not script.search(str(arbs[l].get(k, '')))]
check('RTL locales actually use Arabic script', not bad, bad[:3])

gen = open('lib/l10n/generated/app_localizations.dart').read()
bad = [k for k in source
       if f'get {k} =>' not in gen and f'String {k}(' not in gen]
check('Stub delegate covers every key', not bad, bad[:3])
check('Delegate lists every locale', all(f"'{l}'" in gen for l in LOCALES))
check('app.dart lists every locale',
      all(f"Locale('{l}')" in open('lib/app/app.dart').read() for l in LOCALES))

bad = [k for k in set(re.findall(r'\bl10n\.(\w+)', lib_code))
       if k not in source]
check('Every l10n reference is defined', not bad, bad)

bad = []
for k in source:
    typed = bool(arbs['en'].get(f'@{k}')
                 and 'placeholders' in arbs['en'][f'@{k}'])
    if re.search(rf'\bl10n\.{k}\(', lib_code) and not typed:
        bad.append(f'{k} called with args')
    if re.search(rf'\bl10n\.{k}\b(?!\()', lib_code) and typed:
        bad.append(f'{k} called bare')
check('l10n call arity matches metadata', not bad, bad)

# Arity drift across locales.
#
# Adding a key that already exists silently changes its shape everywhere. A
# `setDeliveryLocation` used as a bare app-bar title became a parameterised
# button label, and every existing call site broke at once — caught only because
# the arity check above happened to notice.
#
# This makes the collision itself visible: if a key takes placeholders in one
# locale and not another, the two disagree about what the key IS, and one of
# them is wrong.
shape_drift = []
for key in source:
    has_ph = {
        loc: bool(re.search(r'\{\w+[,}]', str(arbs[loc].get(key, ''))))
        for loc in LOCALES
    }
    if len(set(has_ph.values())) > 1:
        shape_drift.append(f'{key}: {has_ph}')
check('A key has the same shape in every locale', not shape_drift,
      shape_drift[:3])

# ── User-facing string literals ──────────────────────────────────────────────
#
# The previous version of this pattern required `'[A-Z][^']{4,}'` — a capital
# letter and five characters. That single constraint made whole categories of
# leak structurally invisible to it, and the audit that replaced it found 198
# distinct untranslated strings while this check reported PASS:
#
#   * lowercase text: `Text('edited')`, `return 'now'`
#   * `AuthFailure('Sign in to comment')` and every other Failure constructor,
#     all of which were rendered straight into a SnackBar
#   * `?? 'Someone'` and `?? 'You'` display-name fallbacks
#   * `Semantics(label: '... out of 5 stars')` — invisible to sighted review AND
#     to this check, which is the worst combination available
#   * strings split across two lines by the formatter, since `[^']` stops at the
#     closing quote of the first fragment
#
# Case is no longer part of the test. What separates a user-facing string from an
# identifier is now decided by IDENTIFIER_SHAPED below, on the string's own
# shape, rather than by whether someone happened to capitalise it.
# Parameters that take nothing BUT text a person reads. A literal here is
# prose no matter how it is shaped: `Text('edited')` and `tooltip: 'now'` are
# both leaks, and both are single lowercase words.
#
# Kept separate from AMBIGUOUS_CONTEXTS because the identifier filter has to be
# switched off here. It was not, originally, and a mutation putting
# `Text('edited')` back into the review list passed this check — the same
# lowercase blind spot the rewrite was supposed to close, reintroduced one layer
# down. Verified by mutation now rather than assumed.
TEXT_CONTEXTS = (
    r"Text\(\s*|Text\.rich\(\s*|SelectableText\(\s*"
    r"|labelText:\s*|hintText:\s*|helperText:\s*|errorText:\s*"
    r"|counterText:\s*|prefixText:\s*|suffixText:\s*"
    r"|tooltip:\s*|semanticsLabel:\s*|semanticLabel:\s*"
)

# Parameters that take text sometimes and an identifier, slug or key the rest of
# the time. These keep the identifier filter, or the check drowns in
# `title: 'terms'` and stops being read.
AMBIGUOUS_CONTEXTS = (
    r"label:\s*|title:\s*|subtitle:\s*|message:\s*|body:\s*|subject:\s*"
    r"|text:\s*|retryLabel:\s*|confirmLabel:\s*|cancelLabel:\s*"
    r"|actionLabel:\s*"
)

# One or more adjacent literals, so a sentence the formatter wrapped across
# lines is captured whole rather than half-matched.
LITERAL = r"((?:'(?:[^'\\\n]|\\.)*'\s*)+)"

TEXT_PATTERN = re.compile(r"(?:" + TEXT_CONTEXTS + r")" + LITERAL)
AMBIGUOUS_PATTERN = re.compile(r"(?:" + AMBIGUOUS_CONTEXTS + r")" + LITERAL)

# Failure and Exception constructors.
#
# Every one of these was reaching a user. `Failure.message` was rendered by
# sixteen `Text(f.message)` call sites, so a sentence written in a repository —
# a layer with no BuildContext and therefore no language — was the error text
# for all three locales. They are now translated through `FailureReason`, and
# this keeps it that way.
FAILURE_PATTERN = re.compile(
    r"\b\w*(?:Failure|Exception)\w*\(\s*(?:message:\s*)?" + LITERAL
)

# `?? 'literal'` fallbacks.
#
# `u.displayName ?? 'You'` renders the English word to every locale, and reads
# as deliberate defaulting rather than as a missing translation, which is why it
# survives review.
# `(?<!message )` excludes `e.message ?? 'Error'`. There the literal is the
# diagnostic default behind a provider string, never rendered; what the user sees
# is chosen by FailureReason. Flagging those would bury the real leaks —
# `displayName ?? 'You'` — in forty false positives, and a noisy check is an
# ignored one.
FALLBACK_PATTERN = re.compile(r"(?<!message )\?\?\s*" + LITERAL)

# Bare string literals returned from a `switch` expression arm.
#
# This shape hid ten English labels on the seller order screen — the one sellers
# use more than any other — because the pattern above only looks at widget
# parameters. `=> 'Waiting for payment',` is not inside a `Text(...)` or a
# `label:`, so nothing flagged it.
#
# Restricted to arms that look like enum dispatch (`Foo.bar => 'String'`), which
# is where user-facing label maps live. A lone `=> 'value'` is more often a key,
# an asset path or a debug tag, and flagging those would make the check noisy —
# and a noisy check gets ignored, which is how the ten labels survived.
SWITCH_ARM_PATTERN = re.compile(
    r"\b[A-Z]\w*\.\w+\s*=>\s*" + LITERAL
)

# What is NOT prose, decided on shape rather than on capitalisation.
#
# Identifiers, paths, codes and keys all pass through the contexts above
# legitimately — a Firestore field name inside `Text()` is rare, but
# `?? 'permission-denied'` and `title: 'terms'` are not. Each entry below
# describes a shape a human sentence cannot have.
IDENTIFIER_SHAPED = re.compile(
    r"""^(?:
          [a-z0-9_]+                 # snake_case / lowercase identifier
        | [a-z]+(?:[A-Z][a-z0-9]*)+  # camelCase
        | [A-Z_][A-Z0-9_]*           # CONST_CASE
        # Dotted or hyphenated codes: 'permission-denied',
        # 'app.wave.marketplace'. At least one separator is REQUIRED. Written as
        # a bare `[\w.\-]+` first, which matches any single word and so rejected
        # every one-word literal in the codebase — a mutation reinstating
        # `displayName ?? 'You'` passed the check because of it.
        | [\w\-]+(?:[.\-][\w\-]+)+
        | [\s\W\d]*                  # punctuation, digits, whitespace only
        | \$\{?\w+\}?                # a bare interpolation
        )$""",
    re.X,
)


def is_prose(raw, filter_identifiers=True):
    """True if a literal looks like something a person is meant to read.

    With `filter_identifiers=False` the shape test is skipped, for parameters
    that cannot hold anything but display text.
    """
    # Adjacent literals arrive joined with their quotes; strip them and splice.
    text = ''.join(re.findall(r"'((?:[^'\\\n]|\\.)*)'", raw))
    # Placeholders are not words, and their contents are code.
    bare = re.sub(r'\$\{[^{}]*\}|\$\w+', ' ', text).strip()
    if not bare or bare.startswith(('http', 'assets/', '/', 'geo:')):
        return False
    if filter_identifiers and IDENTIFIER_SHAPED.match(bare):
        return False
    # At least one run of letters. A lone word counts: 'edited' and 'now' were
    # both real leaks, and a minimum length is what let them through before.
    return bool(re.search(r'[^\W\d_]{2,}', bare))


leaked = []
for p, s in dart.items():
    if not p.startswith('lib'):
        continue
    rel = p.replace('lib/', '')
    if rel in UNLOCALIZED_BY_DESIGN:
        continue
    body = strip_comments(s)
    found = [(raw, False) for raw in TEXT_PATTERN.findall(body)]
    found += [(raw, True) for raw in (AMBIGUOUS_PATTERN.findall(body)
                                      + SWITCH_ARM_PATTERN.findall(body)
                                      + FALLBACK_PATTERN.findall(body))]
    for raw, filter_identifiers in found:
        if not is_prose(raw, filter_identifiers):
            continue
        hit = ''.join(re.findall(r"'((?:[^'\\\n]|\\.)*)'", raw))
        if hit not in STRING_EXCEPTIONS:
            leaked.append(f'{rel}: {hit[:40]}')
check('No unintended hardcoded strings', not leaked, leaked[:4])

# Every Failure carrying a written-out message declares a FailureReason.
#
# `Failure.message` is developer-facing and stays English by design — it goes to
# Crashlytics, where a translated string is harder to search. What the USER sees
# comes from `reason`, resolved through `failureText`. So the invariant worth
# checking is not "no English in a Failure", it is "no Failure whose message
# looks like a sentence without a reason to translate it by".
#
# A construction wrapping a provider string (`e.message ?? 'Order failed'`) is
# exempt: the reason defaults to `unknown`, which renders a deliberate generic
# message. A bare prose literal with no reason is the shape that used to reach a
# SnackBar untranslated, and it is what this catches.
reasonless = []
for p, s in dart.items():
    if not p.startswith('lib') or p.endswith('failures.dart'):
        continue
    rel = p.replace('lib/', '')
    if rel in UNLOCALIZED_BY_DESIGN:
        continue
    body = strip_comments(s)
    for m in re.finditer(r'\b\w*(?:Failure|Exception)\w*\(', body):
        # The constructor's arguments, up to the closing paren of the call.
        depth, i = 1, m.end()
        while i < len(body) and depth:
            depth += (body[i] == '(') - (body[i] == ')')
            i += 1
        args = body[m.end():i - 1]
        if 'FailureReason.' in args or '??' in args:
            continue
        literals = re.findall(r"'((?:[^'\\\n]|\\.)*)'", args)
        text = ''.join(literals)
        if not text or not re.search(r'[^\W\d_]{2,}\s+[^\W\d_]{2,}', text):
            continue
        if text in EXCEPTION_MESSAGES_NOT_SURFACED:
            continue
        line = body[:m.start()].count('\n') + 1
        reasonless.append(f'{rel}:{line}: {text[:44]}')
check('Every prose Failure declares a translatable reason', not reasonless,
      reasonless[:4])

# ── Layout that does not mirror ──────────────────────────────────────────────
#
# Two of the three launch locales are right-to-left, so an LTR-only layout is
# broken for most of the intended audience — and it is broken silently, because
# it looks correct on the machine of whoever wrote it.
#
# Flutter mirrors `EdgeInsetsDirectional`, `AlignmentDirectional` and
# `PositionedDirectional` automatically and mirrors nothing else. `left` and
# `right` are screen edges: correct in English, backwards in Arabic and Kurdish.
#
# `Icons.chevron_right` is the subtler one. It does not flip, so a chevron
# meaning "forward, into this row" ends up pointing back towards the start of the
# line. Five screens had one; `DirectionalChevron` picks the glyph from the
# ambient directionality.
# Constructs whose `left`/`right` do not mirror, and the directional form to use.
SIDED_CALLS = [
    ('Positioned(', 'PositionedDirectional(start:/end:)'),
    ('EdgeInsets.only(', 'EdgeInsetsDirectional.only(start:/end:)'),
]

RTL_HAZARDS = [
    (r'\bIcons\.chevron_(?:right|left)\b',
     'Icons.chevron_* does not flip — use DirectionalChevron'),
    (r'\bAlignment\.(?:center|top|bottom)(?:Left|Right)\b',
     'Alignment.*Left/Right — use AlignmentDirectional'),
    (r'\bTextAlign\.(?:left|right)\b',
     'TextAlign.left/right — use TextAlign.start/end'),
]

SIDE_ARG = re.compile(r'\b(left|right)\s*:\s*([^,)]+)')


def call_args(body, open_paren):
    """The text between a call's parens, respecting nesting."""
    depth, i = 1, open_paren + 1
    while i < len(body) and depth:
        depth += (body[i] == '(') - (body[i] == ')')
        i += 1
    return body[open_paren + 1:i - 1]


def sides_mirror(args):
    """True if the call's horizontal sides are symmetric.

    `left: 24, right: 24` is even padding and mirrors to itself; `left: 0,
    right: 0` pins both edges, which is a stretch rather than a side. Neither is
    a bug, and flagging them was the first version of this check — three of the
    four things it reported were symmetric. A check that cries wolf gets
    switched off, so the values are compared instead of the keyword matched.
    """
    sides = {name: value.strip() for name, value in SIDE_ARG.findall(args)}
    return len(sides) == 2 and sides['left'] == sides['right']


rtl = []
for p, s in dart.items():
    if not p.startswith('lib'):
        continue
    rel = p.replace('lib/', '')
    # The chevron widget names both glyphs by definition. The receipt is built
    # with the `pw.` widget set, which is not Flutter and has no ambient
    # Directionality to read; its layout is fixed by the page, not the locale.
    if rel in ('core/widgets/directional_chevron.dart',
               'features/orders/data/receipt_service.dart'):
        continue
    body = strip_comments(s)

    for pattern, why in RTL_HAZARDS:
        for m in re.finditer(pattern, body):
            rtl.append(f'{rel}:{body[:m.start()].count(chr(10)) + 1}: {why}')

    for call, fix in SIDED_CALLS:
        start = 0
        while True:
            at = body.find(call, start)
            if at < 0:
                break
            start = at + len(call)
            args = call_args(body, at + len(call) - 1)
            if not SIDE_ARG.search(args) or sides_mirror(args):
                continue
            line = body[:at].count(chr(10)) + 1
            rtl.append(f'{rel}:{line}: {call[:-1]} sets one side only — {fix}')

check('Layout mirrors for the two RTL locales', not rtl, rtl[:4])

# ── const expressions that read the locale ───────────────────────────────────
#
# `const InputDecoration(hintText: context.l10n.message)` does not compile:
# `const` needs a compile-time constant and a localization lookup is a property
# read on a runtime object.
#
# Four of these were already in the tree — three InputDecorations and a Center —
# which is worth stating plainly, because it means the affected screens could not
# build. It is the natural failure mode of localizing an existing widget: the
# `const` was correct when the string was a literal and nobody removed it when
# the string stopped being one. Cheap to check, and invisible until a build.
LOCALE_LOOKUP = re.compile(
    r'\bcontext\.(?:l10n|money|number|decimal|percent|compact)\b'
    r'|\bfailureText\(|\bDates\.|\blegalDocTitle\('
)

const_conflicts = []
for p, s in dart.items():
    if not p.startswith('lib'):
        continue
    body = strip_comments(s)
    for m in re.finditer(r'\bconst\s+(?=[A-Z_]|\[|\{)', body):
        i = m.end()
        while i < len(body) and body[i] not in '([{;,\n':
            i += 1
        if i >= len(body) or body[i] not in '([{':
            continue
        opener = body[i]
        closer = {'(': ')', '[': ']', '{': '}'}[opener]
        depth, j = 1, i + 1
        while j < len(body) and depth:
            if body[j] == opener:
                depth += 1
            elif body[j] == closer:
                depth -= 1
            j += 1
        hit = LOCALE_LOOKUP.search(body[i:j])
        if hit:
            line = body[:m.start()].count(chr(10)) + 1
            const_conflicts.append(
                f"{p.replace('lib/', '')}:{line}: const encloses "
                f'{hit.group(0)} — drop the const'
            )
check('No const expression reads the locale', not const_conflicts,
      const_conflicts[:4])

# A getter or method named like display text, returning a literal, in a file
# with no BuildContext in reach.
#
# This is the structural version of the check above. Six enums and one data-
# layer value object (ProductSort, ReelUploadStage via ReelUploadProgress,
# OrderTransitions.actionLabel, ReportReason, SellerOrderFilter,
# NotificationChannel, PaymentRail) all defined a `label` next to their values
# and every one had to be moved out, because an enum constant or a domain class
# has no BuildContext and a label defined there is guaranteed to be the one
# string that never translates. It reads as good cohesion at the point someone
# writes it, which is exactly why review does not catch it.
#
# Matched on NAME rather than on the trap itself, because the trap is "no
# context reachable", and reachability through a constructor parameter or an
# outer closure is not something a regex can determine. A name match is a
# strong prior in this codebase — every real instance found this session used
# one of these names — and the brand-name and l10n-resolver files are the
# documented, narrow exceptions.
DISPLAY_TEXT_NAME = re.compile(
    r'\b(?:String|String\?)\s+(?:get\s+)?'
    r'(\w*(?:[Ll]abel|[Tt]itle|[Dd]escription|[Mm]essage|[Nn]ame)\w*)'
    r'\s*(?:\([^)]*\))?\s*=>'
)
# Resolver files are named *_text.dart by convention (see product_sort_text.dart,
# upload_stage_text.dart, order_action_text.dart) specifically so this check —
# and a human skimming the tree — can tell a legitimate resolver from a repeat
# of the trap without opening the file.
RESOLVER_FILE = re.compile(r'_text\.dart$')
NO_CONTEXT_EXCEPTIONS = {
    # Deliberately untranslated brand names — see STRING_EXCEPTIONS above.
    'brandName',
}
misplaced_labels = []
for p, s in dart.items():
    if not p.startswith('lib') or RESOLVER_FILE.search(p):
        continue
    rel = p.replace('lib/', '')
    body = strip_comments(s)
    if 'BuildContext' in body and 'context.l10n' in body:
        continue
    for m in DISPLAY_TEXT_NAME.finditer(body):
        name = m.group(1)
        if name in NO_CONTEXT_EXCEPTIONS:
            continue
        tail = body[m.end():m.end() + 400]
        if re.search(r"'[A-Z][^']{4,}'", tail):
            misplaced_labels.append(f'{rel}: {name}')
check('No display-text getter is defined where it cannot reach a BuildContext',
      not misplaced_labels, misplaced_labels[:4])

# ── Backend ──────────────────────────────────────────────────────────────────
called = set(re.findall(r"httpsCallable\(\s*'(\w+)'", lib_code))
exported = set(re.findall(r'export const (\w+)\s*=\s*onCall\(', ts_all))
check('Every callable has a handler', called <= exported,
      sorted(called - exported))
check('Every callable is exported', all(c in index_ts for c in called),
      [c for c in called if c not in index_ts])

handlers = set(re.findall(
    r'export const (\w+)\s*=\s*'
    r'(?:onCall|onRequest|onSchedule|onDocument\w*)\(',
    ''.join(open(os.path.join(r, f)).read()
            for r, _, fs in os.walk('functions/src')
            for f in fs if f.endswith('.ts') and f != 'index.ts')))
check('Every handler is exported', all(h in index_ts for h in handlers),
      [h for h in handlers if h not in index_ts])

bad = []
for tree in ('functions/src', 'functions/test', 'rules-test/src'):
    for root, _, files in os.walk(tree):
        for f in files:
            if not f.endswith('.ts'):
                continue
            p = os.path.join(root, f)
            s = strip_ts(open(p).read())
            if s.count('{') != s.count('}') or s.count('(') != s.count(')'):
                bad.append(p)
            for imp in re.findall(r'from "(\.\.?/[^"]+)"', s):
                b = os.path.normpath(os.path.join(root, imp))
                if not (os.path.exists(b + '.ts')
                        or os.path.exists(b + '/index.ts')):
                    bad.append(f'{p} -> {imp}')
check('TypeScript balanced and resolving', not bad, bad[:3])

check('Rules braces balanced', rules.count('{') == rules.count('}'))
for fn in ('isModerator', 'notSuspended', 'cooledDown', 'isRealUser'):
    check(f'Rules define {fn}()', f'function {fn}' in rules)

client_collections = set(
    re.findall(r"\.collection\(\s*['\"](\w+)['\"]", lib_code))
ruled = set(re.findall(r'match /(\w+)/', rules)) | RULE_PATH_EXCEPTIONS
check('Every client collection has a rule',
      not (client_collections - ruled),
      sorted(client_collections - ruled))

QUERY = re.compile(
    r"(?:collection|collectionGroup)\(\s*['\"](\w+)['\"]\s*\)"
    r"((?:\s*\.\s*"
    r"(?:where|orderBy|limit|startAt|endAt|startAfter|count|aggregate)"
    r"\([^;]*?\))+)", re.S)
declared = json.load(open('firestore.indexes.json'))['indexes']
missing_idx = set()
for tree, ext in (('lib', '.dart'), ('functions/src', '.ts')):
    for root, _, files in os.walk(tree):
        for f in files:
            if not f.endswith(ext):
                continue
            body = strip_comments(open(os.path.join(root, f)).read())
            for m in QUERY.finditer(body):
                wheres = list(dict.fromkeys(
                    re.findall(r"\.where\(\s*['\"]([\w.]+)['\"]", m.group(2))))
                orders = re.findall(
                    r"\.orderBy\(\s*['\"]([\w.]+)['\"]", m.group(2))
                if len(wheres) + len(orders) < 2:
                    continue
                needed = wheres + [o for o in orders if o not in wheres]
                if not any(i['collectionGroup'] == m.group(1)
                           and all(n in [fl['fieldPath'] for fl in i['fields']]
                                   for n in needed)
                           for i in declared):
                    missing_idx.add((m.group(1), tuple(needed)))
check('Every composite query has an index', not missing_idx,
      sorted(missing_idx)[:3])

# ── Load-bearing chains ──────────────────────────────────────────────────────
# Each of these was broken at some point while every individual file looked
# correct. They are asserted as chains because that is how they fail.
check('Checkout gate chain intact', all([
    'phone_verified' in open('functions/src/orders/placeOrder.ts').read(),
    "unchanged('phone_verified')" in rules,
    'phone_verified: true' in
    open('functions/src/common/onPhoneLinked.ts').read(),
    'onPhoneLinked' in index_ts,
    "httpsCallable('onPhoneLinked')" in
    open('lib/features/auth/data/repositories/'
         'auth_repository_impl.dart').read(),
]))
# `notSuspended` is a substring of `notSuspendedUnused`, so a plain `in` check
# survives the function being renamed out of use. Matched on a word boundary
# against the comment-stripped rules, and required to be CALLED as well as
# declared — a helper nothing invokes protects nothing.
check('Suspension is enforced, not just flagged',
      'setCustomUserClaims' in ts_all
      and 'revokeRefreshTokens' in ts_all
      and re.search(r'\bfunction notSuspended\(\)', rules_code) is not None
      and re.search(r'&&\s*notSuspended\(\)', rules_code) is not None
      and 'isSuspended' in
      open('lib/features/auth/domain/entities/wave_user.dart').read())
# Blocking spans four surfaces. It was previously written to Firestore and read
# only by the profile screen, so the button toggled a flag and blocked accounts
# stayed fully visible — while the report sheet promised otherwise.
BLOCK_SURFACES = [
    'lib/features/reels/presentation/bloc/reels_feed_bloc.dart',
    'lib/features/search/presentation/bloc/search_bloc.dart',
    'lib/features/comments/data/repositories/comment_repository_impl.dart',
    'lib/features/chat/data/repositories/chat_repository_impl.dart',
]
unfiltered = [f for f in BLOCK_SURFACES
              if 'isBlocked' not in open(f).read()
              and 'anyBlocked' not in open(f).read()]
check('Blocking is enforced on every surface', not unfiltered, unfiltered)

check('Offline banner exists and is mounted',
      os.path.exists('lib/core/widgets/offline_banner.dart')
      and 'OfflineBanner' in open('lib/app/widgets/wave_shell.dart').read())

check('Cold-start trace completes on first frame',
      os.path.exists('lib/core/services/startup_trace.dart')
      and 'addPostFrameCallback' in open('lib/bootstrap.dart').read()
      and 'completeOnFirstFrame' in open('lib/bootstrap.dart').read())

# Every append-only collection needs either a retention rule or a stated reason
# it is exempt. Without this, cost and query latency grow with success — the
# funnel counter previously recounted every tap document every thirty minutes.
retention_src = open('functions/src/maintenance/retention.ts').read()
UNBOUNDED = ['otp_requests', 'idempotency', 'moderation_log', 'reports']
uncovered = [c for c in UNBOUNDED if c not in retention_src]
check('Append-only collections have a retention rule', not uncovered, uncovered)
check('Retention job is scheduled and exported',
      'onSchedule' in retention_src and 'enforceRetention' in index_ts)
check('Buy Now taps are consumed, not recounted',
      'consumeTaps' in open('functions/src/counters/profileStats.ts').read()
      and 'FieldValue.increment' in
      open('functions/src/counters/profileStats.ts').read())
check('Retention never prunes pending reports',
      '"pending"' not in retention_src)

deletion_src = open('functions/src/privacy/accountDeletion.ts').read()
PER_USER = ['favourites', 'following', 'fcm_tokens', 'notifications',
            'rate_limits', 'blocks', 'buy_now_taps']
unclean = [c for c in PER_USER if c not in deletion_src]
check('Account deletion clears every per-user collection', not unclean, unclean)

totals_src = open('functions/src/domain/orderTotals.ts').read()
check('Order currency is validated, not overwritten',
      'different currencies' in totals_src and 'firstCurrency' in totals_src)
# Looks for the DECLARATION, not a mention. Renaming the constant leaves its
# call sites referring to it, so a substring check passes on code that no longer
# compiles.
check('Order totals are bounded',
      re.search(r'export const MAX_ORDER_MINOR\s*=', totals_src) is not None
      and 'isSafeInteger' in totals_src)
check('Price bounds enforced on create AND update',
      rules.count('price_minor <= 1000000000') >= 2)

# Order status strings cross the Dart/TypeScript boundary as bare strings, so a
# typo or a renamed state fails at runtime in whichever direction was not
# updated. A guard in webhook.ts once tested for "awaitingPayment", a state that
# never existed — so it matched nothing and would have ignored every webhook.
dart_order = open('lib/features/orders/domain/entities/order.dart').read()
enum_body = re.search(r'enum OrderInternalStatus \{(.*?)\n\}', dart_order, re.S)
ORDER_STATUS = set()
if enum_body:
    for line in enum_body.group(1).split('\n'):
        line = line.strip()
        if not line or line.startswith('/') or '=>' in line or '(' in line:
            continue
        for token in line.replace(';', ',').split(','):
            token = token.strip()
            if token and re.fullmatch(r'[a-z][A-Za-z]*', token):
                ORDER_STATUS.add(token)

# Provider vocabularies and non-order statuses that legitimately differ.
NON_ORDER_STATUS = {
    'completed', 'ignored_late', 'active', 'removed', 'published', 'pending',
    'merged', 'dismissed', 'contentRemoved', 'accountWarned',
    'accountSuspended', 'succeeded', 'failed', 'success', 'draft', 'processing',
}
stray = []
for root, _, files in os.walk('functions/src'):
    for f in files:
        if not f.endswith('.ts'):
            continue
        body = open(os.path.join(root, f)).read()
        for m in re.finditer(r'status:\s*"(\w+)"', body):
            st = m.group(1)
            if st not in ORDER_STATUS and st not in NON_ORDER_STATUS:
                stray.append(f'{f}: {st}')
check('Order statuses in functions match the Dart enum',
      bool(ORDER_STATUS) and not stray, stray[:3])

# NotificationType is load-bearing in three places, and a mismatch in any of
# them is a hard build failure rather than a runtime bug:
#
#   1. the union type itself
#   2. `CHANNEL_OF: Record<NotificationType, Channel>` — TypeScript requires
#      every key, so a missing or extra one fails to compile
#   3. `deepLinkFor`'s switch, which has no `default` and relies entirely on
#      exhaustiveness for `noImplicitReturns` to be satisfied
#
# That third one is the subtle one: the switch compiles today ONLY because it
# covers all ten members. Adding an eleventh type breaks the build in
# `deepLinkFor` with an error pointing at the function rather than at the type
# that changed, which is a confusing place to start debugging. This check names
# the real cause up front.
_notif_src = open('functions/src/notifications/send.ts').read()
_union_block = _notif_src[_notif_src.index('export type NotificationType ='):]
_union_block = _union_block[:_union_block.index(';')]
NOTIFICATION_TYPES = set(re.findall(r'"(\w+)"', _union_block))

_channel_block = _notif_src[_notif_src.index('const CHANNEL_OF'):]
_channel_block = _channel_block[:_channel_block.index('};')]
_channel_keys = set(re.findall(r'^\s+(\w+):', _channel_block, re.M))

_switch_start = _notif_src.index('export function deepLinkFor(')
_switch_open = _notif_src.index('{', _notif_src.index('switch (type)', _switch_start))
_depth, _i = 1, _switch_open + 1
while _depth > 0 and _i < len(_notif_src):
    if _notif_src[_i] == '{':
        _depth += 1
    elif _notif_src[_i] == '}':
        _depth -= 1
    _i += 1
_switch_cases = set(re.findall(r'case "(\w+)":', _notif_src[_switch_open:_i]))

check(
    'Every NotificationType has a channel mapping (Record must be complete)',
    NOTIFICATION_TYPES == _channel_keys,
    sorted(NOTIFICATION_TYPES ^ _channel_keys),
)
check(
    "deepLinkFor's switch is exhaustive, which is what satisfies "
    'noImplicitReturns',
    NOTIFICATION_TYPES == _switch_cases,
    sorted(NOTIFICATION_TYPES ^ _switch_cases),
)

webhook_src = open('functions/src/payments/webhook.ts').read()
check('Webhook cannot resurrect a closed order',
      'awaitingPayment' in webhook_src and 'late_payment_event' in webhook_src)
check('Online payments wait for the webhook',
      'pendingPayment' in open('functions/src/orders/placeOrder.ts').read())

tier_src = open('functions/src/domain/trustTier.ts').read()
check('Trust tier reflects seller cancellations',
      'minFulfilmentRate' in tier_src and 'fulfilmentSampleFloor' in tier_src)
check('Cancellation attribution is pinned in rules',
      "cancelled_by == 'buyer'" in rules and "cancelled_by == 'seller'" in rules)
check('Seller queue filters on internal status, not customer stage',
      '_awaitingSeller' in
      open('lib/features/selling/presentation/bloc/seller_orders_bloc.dart').read())

cart_bloc = open('lib/features/cart/presentation/bloc/cart_bloc.dart').read()
check('Cart survives an app restart',
      'CartStore' in cart_bloc and 'CartRestored' in cart_bloc
      and 'CartRestored' in open('lib/app/app.dart').read())
check('Cart persistence stores no prices',
      'price' not in open('lib/features/cart/data/cart_store.dart').read()
      .split('class CartStore')[1].split('Future<void> save')[1][:600])

# Promise audit.
#
# Every entry here is a claim the app makes to a user in three languages, paired
# with the code that has to be true for it. This lens has found more real bugs
# than any other check in this file: blocking that blocked nothing, a moderator
# queue nobody could read, and a trust-tier warning with no consequence behind
# it. Copy is a specification, and it drifts silently because nobody diffs it
# against behaviour.
PROMISES = {
    'reviewVerifiedOnly': lambda: "status == 'delivered'" in rules,
    'editWindowNote': lambda: "duration.value(48, 'h')" in rules,
    'guestUpgradeBody': lambda: 'CartStore' in open(
        'lib/features/cart/presentation/bloc/cart_bloc.dart').read(),
    'reportSentBody': lambda: 'reporterId' not in open(
        'lib/features/moderation/presentation/pages/'
        'moderation_queue_page.dart').read(),
    'cancelOrderSellerBody': lambda: 'minFulfilmentRate' in open(
        'functions/src/domain/trustTier.ts').read(),
    'deleteAccountBody': lambda: 'pseudonymise' in open(
        'functions/src/privacy/accountDeletion.ts').read(),
    'offlineBannerBody': lambda: 'persistenceEnabled: true' in open(
        'lib/bootstrap.dart').read(),
    'notifOrdersOffWarning': lambda: 'DEFAULT_ENABLED' in open(
        'functions/src/notifications/send.ts').read(),
    'stagePaymentFailedBody': lambda: 'pendingPayment' in open(
        'functions/src/orders/placeOrder.ts').read(),
    'phoneGateShortNote': lambda: 'phone_verified: true' in open(
        'functions/src/common/onPhoneLinked.ts').read(),
}
unbacked = []
for promise, verify in PROMISES.items():
    if promise not in arbs['en']:
        unbacked.append(f'{promise} (copy removed — drop the check too)')
        continue
    try:
        if not verify():
            unbacked.append(promise)
    except Exception as exc:
        unbacked.append(f'{promise} ({exc})')
check('Every user-facing promise is backed by code', not unbacked, unbacked)

# No card data anywhere. Checked separately because it is an absence, and an
# absence is the one thing that regresses without anyone editing the check.
card_leak = []
for tree in ('lib', 'functions/src'):
    for root, _, files in os.walk(tree):
        for f in files:
            if not f.endswith(('.dart', '.ts')):
                continue
            body = open(os.path.join(root, f)).read()
            if re.search(r'card_number|cardNumber|\bcvv\b|expiry_month', body):
                card_leak.append(os.path.join(root, f))
check('No card data stored anywhere', not card_leak, card_leak)

totals = open('functions/src/domain/orderTotals.ts').read()
check('Self-purchase is refused',
      'your own listing' in totals
      and 'uid' in open('functions/src/orders/placeOrder.ts').read()
      .split('computeOrder(')[1][:300])
check('Self-review and self-rating blocked in rules',
      rules.count('seller_id != request.auth.uid') >= 1
      and 'data.seller_id != request.auth.uid' in rules)

phone_fn = open('functions/src/common/onPhoneLinked.ts').read()
check('Phone number is not on the public profile',
      'collection("private")' in phone_fn
      and 'match /private/' in rules)
check('Phone uniqueness is transactional, not a query',
      'phone_claims' in phone_fn and 'runTransaction' in phone_fn)
check('Phone claims are released on account deletion',
      'phone_claims' in open('functions/src/privacy/accountDeletion.ts').read())

# `allow read` in Firestore covers `list` as well as `get`. A collection whose
# contents are individually harmless can still be catastrophic to enumerate —
# promo codes were one query from being handed out wholesale.
# Asserting a deny EXISTS says nothing about whether an allow was added beside
# it. Firestore takes the union of matching rules, so one `allow read` anywhere
# in the block grants it regardless of how many denials sit alongside.
promo_block = rules_code.split('match /promo_codes/{code}')
promo_body = promo_block[1].split('match /redemptions')[0] if len(promo_block) > 1 else ''
promo_grants = re.findall(r'allow\s+([a-z,\s]+?):\s*if\s+(.+?);', promo_body)
promo_leaks = [
    f'{verbs.strip()} -> {cond.strip()}'
    for verbs, cond in promo_grants
    if ('read' in verbs or 'get' in verbs or 'list' in verbs)
    and cond.strip() != 'false'
]
check('Promo codes are not client-readable',
      bool(promo_body) and not promo_leaks, promo_leaks)
check('Promo validation is rate-limited server-side',
      'MAX_ATTEMPTS_PER_HOUR' in
      open('functions/src/promo/validatePromoCode.ts').read())

# Functions called but never defined or imported.
#
# `normaliseLocation` sat in `placeOrder` for a whole pass with no definition
# anywhere — the functions would not have compiled. `tsc` catches this, but
# `tsc` is not run here, and a check that only fires in CI is a check that lets
# a broken tree get packaged.
ts_files = {}
for root, _, files in os.walk('functions/src'):
    for f in files:
        if f.endswith('.ts'):
            path = os.path.join(root, f)
            ts_files[path] = strip_ts(open(path).read())

# Names the language or the SDK provides, or that are obviously not local.
TS_BUILTINS = {
    'require', 'Number', 'String', 'Boolean', 'Array', 'Object', 'Math',
    'JSON', 'Date', 'Promise', 'Map', 'Set', 'Error', 'RegExp', 'parseInt',
    'parseFloat', 'isNaN', 'encodeURIComponent', 'decodeURIComponent',
    'setTimeout', 'clearTimeout', 'Buffer', 'BigInt', 'Symbol', 'if', 'for',
    'while', 'switch', 'catch', 'return', 'function', 'await', 'typeof',
    'constructor', 'super', 'this',
    # `async (request) => {` reads as a call to `async` under a regex that has
    # no grammar. Keywords that can precede a paren all belong here.
    'async', 'else', 'do', 'try', 'new', 'delete', 'void', 'yield', 'in',
    'of', 'case', 'throw', 'import', 'export',
    # Node 18+ globals.
    'fetch', 'structuredClone', 'queueMicrotask',
}

undefined_calls = []
for path, body in ts_files.items():
    defined_here = set(re.findall(
        r'(?:function|const|let|class)\s+(\w+)', body))
    # Interface members and class methods. `createPayment(x): Promise<T>;` in an
    # interface reads as a call to a regex with no grammar, and so does a method
    # body. Both are declarations.
    defined_here |= set(re.findall(r'^\s{2,}(\w+)\s*\([^)]*\)\s*[:{]',
                                   body, re.M))
    defined_here |= set(re.findall(r'(?:async\s+)?(\w+)\s*\([^)]*\)\s*\{',
                                   body))
    # Class methods carrying modifiers, whose parameter lists may span lines:
    # `async createPayment(`, `private signJwt(`. The call sites are all
    # `this.x(...)`, which the call regex already skips, so anything flagged
    # from these files is the declaration itself.
    defined_here |= set(re.findall(
        r'(?:^|\n)\s*(?:private |public |protected |static |async |override )+'
        r'(\w+)\s*\(', body))
    imported = set()
    for group in re.findall(r'import\s*\{([^}]*)\}', body):
        for name in group.split(','):
            imported.add(name.strip().split(' as ')[-1].strip())
    imported |= set(re.findall(r'import\s+\*\s+as\s+(\w+)', body))
    imported |= set(re.findall(r'import\s+(\w+)\s+from', body))

    for name in set(re.findall(r'(?<![.\w])([a-z]\w{3,})\s*\(', body)):
        if name in TS_BUILTINS or name in defined_here or name in imported:
            continue
        undefined_calls.append(f'{os.path.basename(path)}: {name}()')

check('No TypeScript calls to undefined functions',
      not undefined_calls, sorted(set(undefined_calls))[:5])

osm = open('lib/features/location/data/osm_config.dart').read()
check('OSM attribution is part of the map widget, not optional',
      'OsmAttribution' in osm and 'ODbL' in osm)
check('Tile host is overridable and warns in release',
      'TILE_URL' in osm and 'warnIfMisconfigured' in osm
      and 'warnIfMisconfigured' in open('lib/bootstrap.dart').read())
check('README documents the tile-hosting decision',
      'TILE_URL' in readme and 'usage policy' in readme)
check('Brand assets are reproducible from a checked-in source',
      os.path.exists('assets/brand/source/logo_source.png')
      and os.path.exists('tool/generate_brand_assets.py')
      and 'generate_brand_assets' in readme)

# Buy Now shows a price, and the price it shows is kept current.
check('Buy Now button carries a price',
      'buyNowWithPrice' in
      open('lib/features/reels/presentation/widgets/buy_now_button.dart').read())
check('Denormalised Reel price is kept in sync',
      'syncPriceToReels' in
      open('functions/src/products/unlinkProduct.ts').read())

# Delivery location reaches the seller.
check('Delivery location travels from picker to seller',
      'delivery_location' in open('functions/src/orders/placeOrder.ts').read()
      and 'DeliveryLocationCard' in
      open('lib/features/selling/presentation/pages/'
           'seller_orders_page.dart').read())

cascade_src = open('functions/src/privacy/accountDeletion.ts').read()
check('Account deletion erases the delivery pin',
      'delivery_location' in cascade_src)
check('In-flight orders keep delivery details until they land',
      'delivery_details_pending_erasure' in cascade_src
      and 'eraseDeliveryDetails' in retention_src)

# Distinct from the two checks above: those guard the delivery pin ATTACHED TO
# AN ORDER, which lives in Firestore and is reachable by the server-side
# deletion cascade. This guards the LAST-USED pin remembered on the device
# itself — SavedLocationStore, which is deliberately never synced to Firestore
# at all (see its own doc comment), meaning no Cloud Function, including the
# deletion cascade just checked above, can ever reach it. Clearing it is
# structurally a client-side responsibility, and it was previously done only on
# sign-out — the same gap already found twice this session for fields that
# drifted behind a deletion cascade, except this one could never have been
# caught by auditing that cascade, because the cascade was never capable of
# reaching this data regardless of how thorough it was.
delete_account_src = open(
    'lib/features/auth/data/repositories/auth_repository_impl.dart'
).read()
check(
    'Account deletion clears the on-device saved location, not just sign-out',
    'SavedLocationStore' in delete_account_src
    and re.search(
        r'SavedLocationStore>\(\)\.clear\(\)[\s\S]{0,300}?deletion_requests',
        delete_account_src,
    ) is not None,
)

analytics_src = open('lib/core/analytics/analytics_service.dart').read()
# Almost every analytics call is fire-and-forget, and bootstrap reports unhandled
# async errors to Crashlytics as fatal — so an unguarded throw here becomes a
# crash report for a metric, corrupting the number that decides whether to ship.
check('Measurement cannot affect the app',
      analytics_src.count('_neverThrow(') >= 4
      and 'fatal: false' in analytics_src)

# Golden references are generated, not written, so a fresh clone has none. An
# untagged golden test makes `flutter test` red for a new contributor who did
# nothing to cause it — and a suite that is red by default is a suite people stop
# reading.
golden_tests = [
    os.path.join(r, f)
    for r, _, fs in os.walk('test/golden') for f in fs
    if f.endswith('.dart') and 'matchesGoldenFile' in open(os.path.join(r, f)).read()
]
untagged = [f for f in golden_tests if "@Tags(['golden'])" not in open(f).read()]
check('Golden tests are tagged so a fresh clone runs green',
      bool(golden_tests) and not untagged, untagged)
check('Golden tag is configured', os.path.exists('dart_test.yaml')
      and 'golden' in open('dart_test.yaml').read())

# CI regenerating references would make every golden test pass unconditionally,
# forever, and silently. Checked against a comment-stripped view, because the
# comment warning about it says the same words.
ci_yaml = open('.github/workflows/ci.yaml').read()
ci_code = '\n'.join(l.split('#')[0] for l in ci_yaml.split('\n'))
check('CI never regenerates golden references',
      '--update-goldens' not in ci_code)
check('Coverage excludes goldens',
      'flutter test --coverage' in ci_code
      and '--tags golden --coverage' not in ci_code)

# CI must run the codegen step that matters and not the one that does nothing.
#
# `flutter gen-l10n` is mandatory: lib/l10n/generated is a checked-in
# placeholder returning empty strings so a fresh clone analyses before codegen
# has run. Without this step, `flutter analyze` and every widget test in CI
# exercise blank labels instead of real ones — passing while proving less than
# they appear to.
#
# `build_runner` is the opposite. This project has no code generation at all:
# DI is hand-registered (see injector.dart), and there is not one `@freezed`,
# `@JsonSerializable`, `@InjectableInit` or `part` directive in lib/. CI ran it
# twice regardless, contradicting the README and implying codegen was part of
# the workflow. Checked against the comment-stripped CI text specifically
# because the comments explaining this decision say "build_runner" themselves —
# the same trap already hit twice this session by checks that matched their own
# explanation.
_ci_pub_get = ci_code.count('flutter pub get')
check(
    'Every CI job that fetches packages also generates localizations',
    _ci_pub_get > 0
    and ci_code.count('run: flutter gen-l10n') == _ci_pub_get,
)
check(
    'CI does not run build_runner, which has no work to do in this project',
    'build_runner' not in ci_code,
)

# `build.yaml` configures two codegen builders that currently have nothing to
# generate. Keeping it is deliberate (see the header comment in that file), but
# an UNEXPLAINED build.yaml silently contradicts the README's "there is no
# build_runner step" and would reasonably lead someone to add one back — the
# exact mistake just removed from CI. So the file is required to explain itself.
#
# Checked by looking for the explanation rather than by forbidding the file,
# because the file should exist and the annotations it serves are intentionally
# retained.
_build_yaml = open('build.yaml').read()
check(
    'build.yaml documents that it is dormant, so it cannot imply a codegen step',
    'DORMANT' in _build_yaml
    and 'field_rename: snake' in _build_yaml,
)

# A test that asserts nothing passes forever and proves nothing. I nearly shipped
# one this session: a five-class indirection chain ending in
# `throw UnimplementedError()`, which would have compiled and asserted nothing.
#
# Counts assertions per FILE rather than per test, deliberately. Per-test needs a
# parser: assertions legitimately live in local helpers (`expectAtLeast`) and in
# `expectLater`, and a naive per-test scan reported sixteen false positives the
# first time it ran. A file with tests and no assertions at all is unambiguous.
ASSERTIONS = re.compile(r'\b(?:expect|expectLater|verify|verifyNever)\(')
assertion_free = []
for root, _, files in os.walk('test'):
    for f in files:
        if not f.endswith('.dart'):
            continue
        path = os.path.join(root, f)
        body = strip_comments(open(path).read())
        has_tests = re.search(r'\b(?:test|testWidgets)\(', body)
        if has_tests and not ASSERTIONS.search(body):
            assertion_free.append(path)
check('Every test file asserts something', not assertion_free, assertion_free)

# Placeholder assertions that pass regardless of the code under test.
vacuous = []
for root, _, files in os.walk('test'):
    for f in files:
        if not f.endswith('.dart'):
            continue
        path = os.path.join(root, f)
        body = strip_comments(open(path).read())
        for m in re.finditer(
            r'expect\(\s*(true\s*,\s*isTrue|false\s*,\s*isFalse'
            r'|1\s*,\s*1|0\s*,\s*0)\s*\)', body
        ):
            vacuous.append(f'{path}: {m.group(0)}')
        if 'UnimplementedError' in body:
            vacuous.append(f'{path}: contains UnimplementedError')
check('No placeholder assertions', not vacuous, vacuous[:3])

# Secrets that must never be committed.
#
# A service account key is the one that matters: it is full Admin SDK access,
# bypasses every rule in firestore.rules, reads every phone number and delivery
# pin, and can mint the `moderator` and `suspended` claims. Nothing in this
# threat model survives one being public — and they arrive innocently, downloaded
# to run a script and left in the working directory.
gitignore = open('.gitignore').read()
MUST_IGNORE = [
    'serviceAccount', 'firebase-adminsdk-', '*.jks', '*.keystore',
    'key.properties', 'google-services.json', 'GoogleService-Info.plist',
]
unignored = [pat for pat in MUST_IGNORE if pat not in gitignore]
check('Secret-bearing files are gitignored', not unignored, unignored)

# And that none is already in the tree, which .gitignore would not undo.
leaked = []
for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ('.git', 'node_modules', 'build')]
    for f in files:
        if (re.search(r'serviceAccount|service-account|firebase-adminsdk-', f)
                or f.endswith(('.jks', '.keystore'))
                or f in ('key.properties', 'google-services.json',
                         'GoogleService-Info.plist')):
            leaked.append(os.path.join(root, f))
check('No secret-shaped file is in the tree', not leaked, leaked)

# Tests that read source files must anchor to __dirname.
#
# Jest runs with `functions/` as its CWD today, so a bare relative path works —
# until someone runs the suite from the repo root, at which point every one of
# these fails with ENOENT and reads as a code problem rather than a path problem.
cwd_dependent = []
for root, _, files in os.walk('functions/test'):
    for f in files:
        if not f.endswith('.ts'):
            continue
        path_ = os.path.join(root, f)
        body = open(path_).read()
        if 'readFileSync' in body and '__dirname' not in body:
            cwd_dependent.append(path_)
check('Source-reading tests do not depend on the CWD',
      not cwd_dependent, cwd_dependent)

# Node builtins need @types/node. Without it `tsc` fails on `fs` and `__dirname`
# — and it was absent while three test files used both.
fn_pkg = json.load(open('functions/package.json'))
uses_node_builtins = any(
    'from "fs"' in open(os.path.join(r, f)).read()
    or '__dirname' in open(os.path.join(r, f)).read()
    for r, _, fs_ in os.walk('functions') for f in fs_
    if f.endswith('.ts') and 'node_modules' not in r
)
check('Node types are declared if node builtins are used',
      not uses_node_builtins
      or '@types/node' in fn_pkg.get('devDependencies', {}))

# TypeScript has never been compiled here, and three build breaks have been found
# by accident: a missing @types/node, a block-scoped variable referenced outside
# its block, and a positional signature called as though it took an object. These
# two checks approximate the part of `tsc` that catches that class of thing.
def _split_ts_args(text):
    """Top-level comma split. Angle brackets are not delimiters — see strip_ts."""
    depth, current, parts = 0, '', []
    for ch in text:
        if ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
        if ch == ',' and depth == 0:
            parts.append(current)
            current = ''
        else:
            current += ch
    if current.strip():
        parts.append(current)
    return [p for p in parts if p.strip()]


ts_files = [
    os.path.join(r, f)
    for r, _, fs_ in os.walk('functions/src') for f in fs_ if f.endswith('.ts')
]

# What each module actually exports.
ts_exports = {}
for path_ in ts_files:
    body = open(path_).read()
    names = set()
    for pattern in (r'export\s+(?:async\s+)?function\s+(\w+)',
                    r'export\s+(?:const|let|var)\s+(\w+)',
                    r'export\s+(?:abstract\s+)?class\s+(\w+)',
                    r'export\s+interface\s+(\w+)',
                    r'export\s+type\s+(\w+)',
                    r'export\s+enum\s+(\w+)'):
        names |= set(re.findall(pattern, body))
    for block in re.findall(r'export\s*\{([^}]*)\}\s*from', body):
        names |= {n.strip().split(' as ')[-1].strip()
                  for n in block.split(',') if n.strip()}
    ts_exports[os.path.normpath(path_)] = names

bad_imports = []
for path_ in ts_files:
    body = open(path_).read()
    for block, target in re.findall(
        r'import\s*\{([^}]*)\}\s*from\s*"(\.\.?/[^"]+)"', body, re.S
    ):
        base = os.path.normpath(os.path.join(os.path.dirname(path_), target))
        candidate = base + '.ts' if os.path.exists(base + '.ts') \
            else os.path.join(base, 'index.ts')
        candidate = os.path.normpath(candidate)
        if candidate not in ts_exports:
            bad_imports.append(f'{path_}: unresolved {target}')
            continue
        wanted = {n.strip().split(' as ')[0].strip()
                  for n in block.split(',') if n.strip()}
        for missing in sorted(wanted - ts_exports[candidate]):
            bad_imports.append(f'{path_}: `{missing}` not exported by {target}')
check('Every imported TypeScript name is exported', not bad_imports,
      bad_imports[:3])

# Call arity against declaration.
ts_sigs = {}
for path_ in ts_files:
    body = strip_ts(open(path_).read())
    for m in re.finditer(
        r'(?:export\s+)?(?:async\s+)?function\s+(\w+)\s*\(([^)]*)\)', body
    ):
        params = _split_ts_args(m.group(2))
        required = sum(1 for a in params
                       if '?' not in a.split(':')[0] and '=' not in a)
        ts_sigs[m.group(1)] = (required, len(params))

arity_bad = []
for path_ in ts_files:
    body = strip_ts(open(path_).read())
    for fn, (req, total) in ts_sigs.items():
        for m in re.finditer(rf'(?<![.\w]){fn}\s*\(', body):
            if re.search(r'function\s+$', body[max(0, m.start() - 30):m.start()]):
                continue
            i, depth = m.end(), 1
            start = i
            while i < len(body) and depth > 0:
                if body[i] in '([{':
                    depth += 1
                elif body[i] in ')]}':
                    depth -= 1
                i += 1
            count = len(_split_ts_args(body[start:i - 1]))
            if count < req or count > total:
                line = body[:m.start()].count('\n') + 1
                arity_bad.append(
                    f'{os.path.basename(path_)}:{line} {fn}({count}) '
                    f'declares {req}..{total}'
                )
check('TypeScript call arities match declarations', not arity_bad,
      sorted(set(arity_bad))[:3])

check('Reports actually persist',
      'fileReport' in
      open('lib/features/moderation/data/'
           'moderation_repository.dart').read()
      and 'fileReport' in
      open('lib/features/moderation/presentation/widgets/'
           'report_sheet.dart').read())

resolve_report_src = open('functions/src/moderation/resolveReport.ts').read()

# Scoped to resolveReport's OWN body, not the whole file.
#
# The file also exports `dedupeReport`, which has its own unrelated
# `db.runTransaction` call. A file-wide substring check would still see that
# second transaction after `resolveReport`'s were removed — exactly the "a
# mention is not a declaration" flaw already found twice this session for
# MAX_ORDER_MINOR and PHASE_1_ALLOWED_PAYMENT_METHODS, and caught here only
# because the mutation harness proved this specific check could not fail.
_rr_start = resolve_report_src.index('export const resolveReport')
_rr_end = resolve_report_src.index('export const dedupeReport')
resolve_report_body = resolve_report_src[_rr_start:_rr_end]

check(
    'resolveReport reads, checks, and writes a report inside ONE transaction',
    # Not just "runTransaction appears somewhere in the file" — that would
    # pass even if the read-check-write sequence were still split across a
    # bare .get() and a later WriteBatch, which is the exact shape of the bug
    # this guards against. Requires the report read AND the report write to
    # both happen through the same transaction handle.
    'db.runTransaction' in resolve_report_body
    and re.search(r'tx\.get\(reportRef\)', resolve_report_body) is not None
    and re.search(r'tx\.update\(reportRef,', resolve_report_body) is not None
    # And that nothing regressed back to committing the decision through an
    # unconditional batch — the original bug's exact mechanism.
    and 'db.batch()' not in resolve_report_body,
)
check(
    'resolveOwner reads through the transaction, not a bare .get()',
    # A read outside `tx` inside a transactional function is invisible to
    # Firestore's conflict detection — it would silently reopen the same race
    # the surrounding transaction exists to close, while looking identical to
    # correct code at a glance.
    re.search(r'async function resolveOwner\(\s*tx:', resolve_report_src)
    is not None
    and 'await tx.get(db.collection' in resolve_report_src,
)

upload_slot_src = open('functions/src/bunny/uploadSlot.ts').read()


def _bracket_matched_span(src, open_marker, after_text_before_brace=''):
    """Finds `open_marker`, then returns the text up to the matching `}` of
    the FIRST `{` that follows it — via bracket-depth counting, not a regex.

    A greedy or lazy regex quantifier like `[^}]*` breaks the moment the span
    contains its own nested braces, which `pending_uploads...set({...})` does.
    This is the second time a check in this file needed the same fix for the
    same reason — see the `resolveReport` scoping note above — so it is
    factored out rather than repeated a third time by hand.
    """
    marker_idx = src.find(open_marker)
    if marker_idx == -1:
        return None
    brace_idx = src.find('{', marker_idx + len(open_marker) + len(after_text_before_brace))
    if brace_idx == -1:
        return None
    depth = 1
    i = brace_idx + 1
    while depth > 0 and i < len(src):
        if src[i] == '{':
            depth += 1
        elif src[i] == '}':
            depth -= 1
        i += 1
    return src[marker_idx:i]


_upload_try_span = _bracket_matched_span(upload_slot_src, 'try {')
_upload_catch_span = _bracket_matched_span(
    upload_slot_src, 'catch (writeError) '
)
check(
    'A failed ownership write after Bunny creates a video does not leak it',
    # The write must be inside a try, and the catch must attempt a
    # compensating delete rather than just surfacing the error — otherwise a
    # Firestore blip at exactly the wrong moment leaves a real, billed video
    # nobody in this system owns and no existing cleanup job can find.
    _upload_try_span is not None
    and 'pending_uploads' in _upload_try_span
    and '.set(' in _upload_try_span
    and _upload_catch_span is not None
    and '"DELETE"' in _upload_catch_span,
)

check('README covers native folder generation',
      'Generate the native platform folders' in readme)
check('README requires gen-l10n', 'gen-l10n' in readme)
check('README lists all four required Bunny secrets',
      all(f'secrets:set {name}' in readme for name in
          ('BUNNY_TOKEN_AUTH_KEY', 'BUNNY_PULL_ZONE_HOST',
           'BUNNY_API_KEY', 'BUNNY_LIBRARY_ID')))
# ZainCash secrets are still documented (for Phase 2) but the README must say
# plainly not to set them now — otherwise an operator follows the doc top to
# bottom and provisions a merchant account Phase 1 does not need at all.
check('README marks ZainCash secrets as not required for Phase 1',
      'Do not set the four `ZAINCASH_*` secrets' in readme
      and all(f'secrets:set {name}' in readme for name in
              ('ZAINCASH_SECRET', 'ZAINCASH_MERCHANT_ID',
               'ZAINCASH_MSISDN', 'ZAINCASH_BASE_URL')))
# The webhook export that WOULD force those secrets at deploy time must stay
# paused. If someone uncomments it without reading the surrounding comment,
# `firebase deploy` fails on missing secrets — annoying but safe. If this check
# regresses, it means the export is live while the README still says cash-only,
# which is the dangerous direction to be wrong in.
check('ZainCash webhook export is paused, matching the cash-only phase',
      re.search(r'^export \{ paymentWebhook \}', index_ts, re.M) is None
      and '// export { paymentWebhook }' in index_ts)
# placeOrder must actually enforce cash-only — this is the real boundary, not
# the UI picker. See the long comment at the guard itself for why.
# Matches the DECLARATION, not just a mention of the name — the same shape of
# bug as MAX_ORDER_MINOR above. Renaming just the `const` would leave the
# `.has(paymentMethodId)` call referring to a name that no longer exists (a
# real compile error, which is good), but a plain substring check would still
# see the old name in that call site and report green on code that cannot
# build.
check('placeOrder rejects every payment method except cash on delivery',
      re.search(
          r'const PHASE_1_ALLOWED_PAYMENT_METHODS\s*=\s*new Set\(',
          open('functions/src/orders/placeOrder.ts').read(),
      ) is not None)
check('PaymentRail.phase1EnabledRails is cash-only',
      re.search(
          r'phase1EnabledRails\s*=\s*\{\s*PaymentRail\.cashOnDelivery\s*\}',
          open('lib/features/checkout/domain/entities/payment_method.dart')
          .read(),
      ) is not None)

check('Zero TODOs',
      sum(s.count('TODO') for s in dart.values()) + ts_all.count('TODO') == 0)
check('Zero skipped tests',
      sum(s.count('skip:') for p, s in dart.items()
          if not p.startswith('lib')) == 0)
# A closure whose body is only a comment is still a dead button, and the naive
# `() {}` pattern misses it — `lib_code` has comments stripped, so a
# comment-only body arrives here as `() {  }`. The Buy Now button on the core
# conversion path was exactly this shape and went unnoticed for several passes.
dead_callbacks = re.findall(
    r'on(?:Pressed|Tap):\s*\(\)\s*(?:=>\s*)?\{\s*\}', lib_code)
check('Zero dead callbacks', not dead_callbacks, dead_callbacks[:3])

# The placeholder pattern that hid it: a widget with hardcoded literals and a
# comment promising to wire it up later. These read as finished code.
PLACEHOLDER_MARKERS = [
    'Placeholder values', 'Wire to a BLoC', 'placeholder for now',
    'TODO', 'FIXME', 'stub for now',
]
placeholders = []
for p_, s_ in dart.items():
    if not p_.startswith('lib'):
        continue
    for marker in PLACEHOLDER_MARKERS:
        if marker in s_:
            placeholders.append(f'{p_.replace("lib/", "")}: {marker}')
check('No placeholder widgets left in lib/', not placeholders, placeholders[:4])

# ── Report ───────────────────────────────────────────────────────────────────
WIDTH = 66
print('PROJECT CHECK'.center(WIDTH))
print('=' * WIDTH)
for name, ok, detail in results:
    print(f"  {'PASS' if ok else 'FAIL'}  {name}")
    if not ok and detail:
        print(f'        → {detail}')
print('=' * WIDTH)
passed = sum(1 for _, ok, _ in results if ok)
print(f'{passed}/{len(results)} passing')
sys.exit(0 if passed == len(results) else 1)
