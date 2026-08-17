#!/usr/bin/env python3
"""Proves the checks in `check_project.py` can fail.

    python3 tool/verify_checks.py                 # all mutations (slow)
    python3 tool/verify_checks.py payment cash    # only matching labels
    python3 tool/verify_checks.py --list          # show labels, run nothing

A check that has only ever been green is indistinguishable from a check that
cannot fail. Three checks in this repository were silently broken at some point
and every one of them reported PASS: one matched its own explanatory comment, one
searched a window too small to contain the rule it was checking, and one was
skipped entirely by a guard condition that was already true.

None of that is visible from a passing run. So each mutation below breaks one
invariant in the smallest way that should be caught, and asserts the intended
check turns red. Then it restores the file and confirms the suite is green again —
because a harness that leaves the tree dirty is worse than no harness.

This is deliberately not exhaustive. It covers the invariants whose failure would
be expensive and silent: money, identity, permissions, and secrets. A check
guarding a naming convention can afford to be untested; a check guarding "nobody
can buy from themselves" cannot.

## Why filtering exists

Every mutation runs the whole checker, which takes about thirteen seconds. At
twenty-four mutations that is roughly six minutes — long enough that the full run
exceeds a typical command timeout, and long enough that people stop running it
locally, which defeats the point entirely.

CI runs the full set, where six minutes is acceptable. Locally, pass substrings
to run only what a change actually touches. The filter matches against mutation
labels, so `payment` runs everything payment-related without needing to know how
many that is.
"""
import os
import shutil
import subprocess
import sys
import tempfile

CHECKER = ["python3", "tool/check_project.py"]

# (label, expected substring in the failing check's name, file, find, replace)
#
# `find` must appear exactly once, so a mutation cannot silently apply somewhere
# unintended — which is the same failure mode the harness exists to expose.
#
# `replace` must NOT contain the token being removed. Two mutations here
# originally read `false /* isBlocked removed */` and
# `# serviceAccount pattern removed`, which left the searched substring in the
# file and made the mutation a no-op. The checks looked weak; the harness was
# broken. A harness that produces false alarms is as useless as a check that
# cannot fail, so this is asserted below rather than left to care.
# Mutations that ADD something harmful rather than removing something protective.
# These keep the anchor text by necessity — granting a read permission means
# inserting a line, not deleting one — so the "replacement must not contain the
# token" guard does not apply to them.
APPENDS = {
    "promo codes readable",
    "CI regenerates goldens",
    # Both insert a harmful line while keeping the anchor text around it, so
    # the "replacement must not contain the token it removes" guard does not
    # apply — the point is what gets ADDED, not what is taken away.
    "a CI job fetches packages without generating localizations",
    "build_runner creeps back into CI",
}

MUTATIONS = [
    (
        "an eleventh notification type with no channel mapping",
        "Every NotificationType has a channel mapping",
        "functions/src/notifications/send.ts",
        '  | "marketing";',
        '  | "marketing"\n  | "price_drop";',
    ),
    (
        "a CI job fetches packages without generating localizations",
        "Every CI job that fetches packages also generates localizations",
        ".github/workflows/ci.yaml",
        "      - run: npm run build --prefix functions\n"
        "      - run: flutter pub get",
        "      - run: npm run build --prefix functions\n"
        "      - run: flutter pub get\n"
        "      - run: flutter pub get",
    ),
    (
        "build_runner creeps back into CI",
        "CI does not run build_runner, which has no work to do in this project",
        ".github/workflows/ci.yaml",
        "      - run: dart format --output=none --set-exit-if-changed .",
        "      - run: dart run build_runner build\n"
        "      - run: dart format --output=none --set-exit-if-changed .",
    ),
    (
        "on-device saved location no longer cleared on account deletion",
        "Account deletion clears the on-device saved location, not just "
        "sign-out",
        "lib/features/auth/data/repositories/auth_repository_impl.dart",
        "await getIt<SavedLocationStore>().clear();",
        "// clear() removed for this test",
    ),
    (
        "orphaned Bunny video cleanup removed",
        "A failed ownership write after Bunny creates a video does not "
        "leak it",
        "functions/src/bunny/uploadSlot.ts",
        'method: "DELETE", headers: { AccessKey: BUNNY_API_KEY.value() } }',
        'method: "GET", headers: { AccessKey: BUNNY_API_KEY.value() } }',
    ),
    (
        "an untranslatable label returns to an enum with no BuildContext",
        "No display-text getter is defined where it cannot reach a BuildContext",
        "lib/features/marketplace/domain/entities/product.dart",
        "  topRated,\n}",
        "  topRated;\n\n"
        "  String get label => 'Top rated';\n"
        "}",
    ),
    (
        "resolveReport's transaction wrapper removed, reopening the race",
        "resolveReport reads, checks, and writes a report inside ONE "
        "transaction",
        "functions/src/moderation/resolveReport.ts",
        "const { targetType, targetId, suspendedUid } = await "
        "db.runTransaction(",
        "const legacyBatchResult = await notATransaction(",
    ),
    (
        "placeOrder cash-only guard removed",
        "placeOrder rejects every payment method except cash on delivery",
        "functions/src/orders/placeOrder.ts",
        'const PHASE_1_ALLOWED_PAYMENT_METHODS = new Set(["cash_on_delivery"]);',
        'const ALLOWED_METHODS_RENAMED = new Set(["cash_on_delivery"]);',
    ),
    (
        "an online rail re-enabled client-side",
        "PaymentRail.phase1EnabledRails is cash-only",
        "lib/features/checkout/domain/entities/payment_method.dart",
        "phase1EnabledRails = {PaymentRail.cashOnDelivery}",
        "phase1EnabledRails = "
        "{PaymentRail.cashOnDelivery, PaymentRail.zainCash}",
    ),
    (
        "ZainCash webhook export uncommented",
        "ZainCash webhook export is paused",
        "functions/src/index.ts",
        "// export { paymentWebhook } from \"./payments/webhook\";",
        "export { paymentWebhook } from \"./payments/webhook\";",
    ),
    (
        "self-purchase allowed",
        "Self-purchase is refused",
        "functions/src/domain/orderTotals.ts",
        "You cannot buy your own listing",
        "placeholder message",
    ),
    (
        "currency silently overwritten",
        "Order currency is validated",
        "functions/src/domain/orderTotals.ts",
        "different currencies",
        "mixed units are fine",
    ),
    (
        "order total unbounded",
        "Order totals are bounded",
        "functions/src/domain/orderTotals.ts",
        "MAX_ORDER_MINOR = 1_000_000_000",
        "UNUSED_CEILING = 1_000_000_000",
    ),
    (
        "checkout gate unreachable",
        "Checkout gate chain intact",
        "lib/features/auth/data/repositories/auth_repository_impl.dart",
        "httpsCallable('onPhoneLinked')",
        "httpsCallable('onPhoneLinkedTypo')",
    ),
    (
        "suspension not enforced in rules",
        "Suspension is enforced",
        "firestore.rules",
        "function notSuspended()",
        "function notSuspendedUnused()",
    ),
    (
        "promo codes readable",
        "Promo codes are not client-readable",
        "firestore.rules",
        "match /promo_codes/{code} {",
        "match /promo_codes/{code} {\n      allow read: if signedIn();",
    ),
    (
        "blocking not applied to the feed",
        "Blocking is enforced",
        "lib/features/reels/presentation/bloc/reels_feed_bloc.dart",
        "_blocks.isBlocked(r.authorId)",
        "false",
    ),
    (
        "service account key not ignored",
        "Secret-bearing files are gitignored",
        ".gitignore",
        "*serviceAccount*.json",
        "# pattern removed",
    ),
    (
        "delivery pin survives deletion",
        "Account deletion erases the delivery pin",
        "functions/src/privacy/accountDeletion.ts",
        "delivery_location: admin.firestore.FieldValue.delete(),",
        "// pin erasure removed",
    ),
    (
        "analytics can throw",
        "Measurement cannot affect the app",
        "lib/core/analytics/analytics_service.dart",
        "fatal: false",
        "fatal: true",
    ),
    (
        "a locale loses a key",
        "All locales share identical keys",
        "lib/l10n/app_ar.arb",
        '"buyNow"',
        '"buyNowRenamed"',
    ),
    (
        "a hardcoded string reappears",
        "No unintended hardcoded strings",
        "lib/features/cart/presentation/pages/cart_page.dart",
        "title: Text(context.l10n.cart)",
        "title: const Text('Shopping cart')",
    ),
    (
        "CI regenerates goldens",
        "CI never regenerates golden references",
        ".github/workflows/ci.yaml",
        "run: flutter test --tags golden",
        "run: flutter test --tags golden --update-goldens",
    ),
    (
        "a dead callback returns",
        "Zero dead callbacks",
        "lib/features/reels/presentation/widgets/reel_action_rail.dart",
        "onTap: () => _openReport(context),",
        "onTap: () {},",
    ),
    (
        "TypeScript import breaks",
        "Every imported TypeScript name is exported",
        "functions/src/notifications/triggers.ts",
        'import { sendNotification } from "./send";',
        'import { sendNotification, missingExport } from "./send";',
    ),
]


def run_checker():
    """Returns (passing, total, failing_check_names)."""
    result = subprocess.run(CHECKER, capture_output=True, text=True)
    failing = [
        line.strip()[6:].strip()
        for line in result.stdout.splitlines()
        if line.strip().startswith("FAIL")
    ]
    summary = result.stdout.strip().splitlines()[-1] if result.stdout else ""
    return summary, failing


def main() -> int:
    filters = [a for a in sys.argv[1:] if not a.startswith('-')]

    if '--list' in sys.argv[1:]:
        print(f"{len(MUTATIONS)} mutations:\n")
        for label, *_ in MUTATIONS:
            print(f"  {label}")
        return 0

    if filters:
        selected = [
            m for m in MUTATIONS
            if any(f.lower() in m[0].lower() for f in filters)
        ]
        if not selected:
            print(f"No mutation label matches {filters}. Try --list.")
            return 1
        print(
            f"Running {len(selected)} of {len(MUTATIONS)} mutations "
            f"matching {filters}.\n"
        )
    else:
        selected = MUTATIONS

    # Recover from a previous run that was killed before it could restore.
    #
    # Every mutation is undone in a `finally`, which handles exceptions — but
    # not a hard kill. A timeout or Ctrl-C bypasses `finally` entirely and
    # leaves mutated source in the working tree with no warning, which is worse
    # than any bug this harness exists to find: the repository silently
    # contains code nobody wrote on purpose. That happened twice while this
    # harness was being extended, once leaving a deliberately-broken TypeScript
    # import behind and once leaving five files mutated — noticed only because
    # a later check failed for an unrelated-looking reason.
    #
    # So backups go somewhere predictable rather than a random temp dir, and
    # any left over from a killed run are restored before doing anything else.
    backups = os.path.join(tempfile.gettempdir(), 'wave_verify_checks_backups')
    if os.path.isdir(backups):
        stale = os.listdir(backups)
        if stale:
            print(
                f"Recovering {len(stale)} file(s) from a previous run that was "
                "killed before it could restore them:"
            )
            for name in stale:
                target = name.replace('__', '/')
                shutil.copy(os.path.join(backups, name), target)
                print(f"  restored {target}")
            print()
        shutil.rmtree(backups, ignore_errors=True)
    os.makedirs(backups, exist_ok=True)

    baseline_summary, baseline_failures = run_checker()
    if baseline_failures:
        print("The suite is already failing — fix that before running this:")
        for f in baseline_failures:
            print(f"  {f}")
        return 1
    print(f"baseline: {baseline_summary}\n")

    results = []

    try:
        for label, expected, path, find, replace in selected:
            if not os.path.exists(path):
                results.append((label, "SKIP", f"{path} not found"))
                continue

            original = open(path).read()
            occurrences = original.count(find)

            if find in replace and label not in APPENDS:
                # A replacement containing the token it removes leaves the string
                # in place, so the mutation changes nothing and the check
                # correctly stays green. That reads as a weak check and is not.
                results.append(
                    (label, "BAD", "replacement still contains the searched token")
                )
                continue

            if occurrences != 1:
                # A mutation that matches zero times tests nothing and one that
                # matches many times may break something other than the
                # invariant under test. Either way the result would be
                # meaningless, so it is reported rather than run.
                results.append(
                    (label, "BAD", f"anchor appears {occurrences}x in {path}")
                )
                continue

            backup = os.path.join(backups, path.replace("/", "__"))
            shutil.copy(path, backup)

            try:
                open(path, "w").write(original.replace(find, replace, 1))
                _, failures = run_checker()
                caught = any(expected in name for name in failures)
                results.append(
                    (
                        label,
                        "OK" if caught else "MISSED",
                        expected if caught else f"expected `{expected}` to fail",
                    )
                )
            finally:
                shutil.copy(backup, path)

        width = max(len(label) for label, *_ in results)
        print("MUTATION".ljust(width + 2) + "RESULT")
        print("-" * (width + 40))
        for label, status, detail in results:
            print(f"{label.ljust(width + 2)}{status}")
            if status != "OK":
                print(f"{' ' * (width + 2)}  {detail}")

        missed = [r for r in results if r[1] != "OK"]

        final_summary, final_failures = run_checker()
        print(f"\nrestored: {final_summary}")
        if final_failures:
            print("HARNESS LEFT THE TREE DIRTY:")
            for f in final_failures:
                print(f"  {f}")
            return 1

        if missed:
            print(f"\n{len(missed)} of {len(results)} mutations went undetected.")
            print("A check that cannot fail is not protecting anything.")
            return 1

        print(f"\nAll {len(results)} mutations detected.")
        return 0

    finally:
        shutil.rmtree(backups, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
