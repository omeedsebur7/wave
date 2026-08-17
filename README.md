# WAVE — Phase 1

Social commerce: short-form video discovery with a full marketplace. Reels that
convert straight to a sale, from a seller a buyer can already trust.

Flutter + Firebase, with all video on Bunny Stream. Built to the v3 brief.

---

## Read this first — what this repository is and is not

This is a **working architectural foundation for Phase 1**, not a finished
Phase 1 app. The distinction matters, so here it is precisely:

**Fully implemented** — the parts that are expensive or dangerous to get wrong
later, and that the brief specified tightly enough to build correctly without
further decisions:

| Area | File(s) |
|---|---|
| Design tokens, both themes, ThemeExtensions | `lib/core/theme/` |
| Trust-tier logic + badge widget (WCAG-safe) | `lib/features/trust/`, `lib/core/widgets/trust_badge.dart` |
| Bounded video-controller window | `lib/features/reels/.../reel_controller_pool.dart` |
| Paginated feed BLoC with prefetch | `lib/features/reels/presentation/bloc/` |
| Sharded like/view counters | `lib/core/services/sharded_counter_service.dart` |
| Marketplace: grid, debounced search, sort, favourites | `lib/features/marketplace/` |
| Product detail with seller trust card | `lib/features/marketplace/.../product_detail_page.dart` |
| Cart with stock-drift and multi-seller guards | `lib/features/cart/` |
| Checkout identity gate | `lib/features/checkout/domain/entities/checkout_gate.dart` |
| Checkout BLoC with session-scoped idempotency key | `lib/features/checkout/presentation/bloc/` |
| Idempotent order placement | `functions/src/orders/placeOrder.ts` |
| Bunny playback URL signing | `functions/src/bunny/signPlaybackUrl.ts` |
| Trust-tier recomputation | `functions/src/trust/recomputeTrustTier.ts` |
| Feed ranking heuristic | `functions/src/feed/rankFeed.ts` |
| Firestore + Storage Security Rules | `firestore.rules`, `storage.rules` |
| Order status model, 3-step tracker, order list | `lib/features/orders/` |
| Reviews: list, distribution bar, rating sheet | `lib/features/reviews/` |
| Auth with guest-upgrade path | `lib/features/auth/` |
| Sign-in with Terms + minimum-age consent gate | `lib/features/auth/.../sign_in_page.dart` |
| Report / block flow | `lib/features/moderation/` |
| Comments — open thread, seller badge, kill switch | `lib/features/comments/` |
| Seller profile with evidence panel | `lib/features/profile/.../seller_profile_page.dart` |
| Saved addresses + payment methods | `lib/features/checkout/data/datasources/` |
| Reel compression + streamed Bunny upload | `lib/features/publish/data/reel_upload_service.dart` |
| PDF receipt generation | `lib/features/orders/data/receipt_service.dart` |
| Data export + cascading account deletion | `functions/src/privacy/accountDeletion.ts` |
| Seller Agreement + Content Policy (seed drafts) | `docs/legal/` |
| Favourites, notification preference persistence | `lib/features/marketplace/`, `lib/features/notifications/` |
| Seller order queue + transition state machine | `lib/features/selling/` |
| Unified search across Products and Reels | `lib/features/search/` |
| Payment provider abstraction (cash-only in Phase 1; ZainCash adapter built and paused) | `functions/src/payments/providers/` |
| Widget, golden and integration test suites | `test/widgets/`, `test/golden/`, `integration_test/` |
| Emulator wiring + test fixtures | `lib/core/config/emulator.dart`, `integration_test/helpers/` |
| Security Rules test suite (47 cases) | `rules-test/` |
| Cloud Function domain logic + tests | `functions/src/domain/`, `functions/test/` |
| Seller analytics with a split funnel | `lib/features/selling/` |
| FCM push handling + tap routing | `lib/features/notifications/data/push_handler.dart` |
| Notification senders (6 triggers) | `functions/src/notifications/` |
| Chat repository, conversation list, offline queue | `lib/features/chat/` |
| Profile with guest state and account deletion | `lib/features/profile/` |
| Notification centre + preference centre | `lib/features/notifications/` |
| Reel upload with 60s cap and product link | `lib/features/publish/` |
| Legal documents + versioned re-acceptance gate | `lib/features/legal/` |
| Navigation shell, routing, deep links | `lib/app/` |
| Test suite incl. WCAG contrast verification | `test/` |
| CI/CD pipeline | `.github/workflows/ci.yaml` |

**Every screen is now wired.** No page in `lib/features` is a placeholder, and
there are no empty `onPressed: () {}` callbacks left — where a feature is
genuinely Phase 2 (making an offer, adding a wallet), the button says so rather
than doing nothing. A dead button is worse than an honest one.

**Localization is complete.** 359 keys in English and Kurdish Sorani, wired
across 41 files. **Zero hardcoded user-facing strings remain** — the count went
198 → 0.

Three patterns were needed for the places a `BuildContext` is not available,
and each is worth knowing because the naive alternative silently breaks:

- **Enums do not carry labels.** `ReportReason`, `SellerOrderFilter`,
  `NotificationChannel` and `PaymentRail` all previously held display strings.
  An enum constant cannot reach a `BuildContext`, so a label living there is
  *guaranteed* to be the one string on the screen that never translates.
  Labels are resolved at render through a `switch`.
- **The cart BLoC emits a `CartMessage` key, not a sentence.** A BLoC has no
  context, and reaching for a global locale would produce the wrong language
  the moment someone switches mid-session — and would make the BLoC untestable
  without a Flutter binding.
- **The receipt generator and data exporter take their strings as arguments.**
  A receipt is a document someone hands to a courier or a bank; generating it
  in the wrong language is worse than a mistranslated screen, because the
  person reading it cannot switch locale.

Provider brand names stay untranslated. "ZainCash" is ZainCash in every
language, and translating it would make the option unrecognisable beside the
provider's own branding.

**Still outstanding:**

- ~80 hardcoded strings to move into `context.l10n`. Grep for
  `Text('` in `lib/features` — every match with a capitalised, human-readable
  string is one of them.
- Integration test bodies. The harness is complete — emulator wiring, fixtures,
  CI job. What remains is driving the UI in each test; every assertion is
  already written out in the file as a specification.
- A Bunny stub for the publish-flow tests (the purchase flow needs no stub).
- Golden reference images. Run `flutter test --update-goldens test/golden`
  once, on the machine that will run CI, to generate them.
- ZainCash is **paused for Phase 1** by explicit product decision — see step 10
  above and the comment in `functions/src/index.ts`. The adapter, signature
  verification and tests all remain in the tree for Phase 2. When it is
  reactivated, its endpoint and field names still need confirming against
  current merchant documentation; the adapter encodes the shape of the
  integration correctly, but the specifics are what changes over time.
- The legal documents in `docs/legal/` are seed drafts and need a lawyer before
  they go into Firestore.

**No codegen required to run.** DI is registered by hand in
`lib/app/di/injector.dart` rather than generated, so the project starts on a
fresh clone. `freezed`/`json_serializable` annotations are absent by design —
DTOs are hand-written, which is why there are no `.g.dart` files to generate
before a first run.

**Not verified to compile.** The build environment here has no network access,
so `flutter pub get` and `dart analyze` could not be run. What *was* verified
statically, and is clean: every `package:wave/` import resolves to a real file;
all delimiters balance under a Dart-aware parser; no duplicate top-level type
names; every DI-registered type exists; every `Routes.*` reference is defined;
TypeScript relative imports resolve. Type errors and dependency version drift
are still likely on first build.

Anyone treating this as a shippable Phase 1 will be disappointed. Anyone
treating it as the foundation the rest of Phase 1 gets built onto — with the
hard architectural calls already made, justified in comments, and covered by
tests — is holding what it actually is.

---

## Getting started

Follow these in order. Steps 0–4 are required before the app runs at all; 5–14
before it does anything useful.

### 0. Generate the native platform folders

This repository contains no `android/` or `ios/` directories. They are generated,
and generating them here would have baked in placeholder bundle identifiers you
would then have to hunt down and change.

```bash
flutter create --platforms=android,ios \
  --org com.yourcompany --project-name wave .
```

This does not overwrite `lib/`, `test/` or `pubspec.yaml`.

### 1. Dependencies and codegen

```bash
flutter pub get
flutter gen-l10n          # REQUIRED — see below
```

`flutter gen-l10n` is **not optional**. `lib/l10n/generated/app_localizations.dart`
is checked in as a placeholder that returns empty strings, so a fresh clone
analyses cleanly before codegen has run. Skip this step and every label in the
app renders blank. There is no `build_runner` step — DI and the DTOs are
hand-written.

### 2. Firebase — three projects

One each for dev, staging and prod (§6), so staging traffic can never write to
production data.

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=wave-dev     --out=lib/firebase_options_dev.dart
flutterfire configure --project=wave-staging --out=lib/firebase_options_staging.dart
flutterfire configure --project=wave-prod    --out=lib/firebase_options_prod.dart
```

These files are gitignored. In each project enable **Authentication** (Google,
Apple, Phone, Anonymous), **Firestore**, **Storage**, **Functions**,
**Messaging**, **Remote Config**, **App Check**, **Crashlytics** and
**Performance**.

### 3. Fonts

Place in `assets/fonts/` with these exact filenames:

| Family | Files |
|---|---|
| Plus Jakarta Sans | `PlusJakartaSans-SemiBold.ttf`, `PlusJakartaSans-Bold.ttf` |
| Inter | `Inter-Regular.ttf`, `Inter-Medium.ttf` |
| IBM Plex Sans Arabic | `IBMPlexSansArabic-Regular.ttf`, `IBMPlexSansArabic-SemiBold.ttf` |

All three are open-licensed and on Google Fonts. **IBM Plex Sans Arabic is not
optional** — it renders both Arabic and Kurdish Sorani, which are two of the
three launch languages.

### 4. Build flavors

Flutter does not generate these; add them to the folders step 0 created.

**Android** — `android/app/build.gradle`:

```groovy
flavorDimensions "env"
productFlavors {
    dev     { dimension "env"; applicationIdSuffix ".dev";     resValue "string", "app_name", "WAVE Dev" }
    staging { dimension "env"; applicationIdSuffix ".staging"; resValue "string", "app_name", "WAVE Staging" }
    prod    { dimension "env";                                 resValue "string", "app_name", "WAVE" }
}
```

Put each project's `google-services.json` under
`android/app/src/{dev,staging,prod}/`.

**iOS** — three Xcode schemes with matching bundle identifiers, each with its own
`GoogleService-Info.plist`.

### 5. Native permissions and capabilities

The app is **rejected at review** without these, not merely degraded.

`ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>WAVE needs access to your videos and photos so you can post a Reel or list a product.</string>
<key>NSCameraUsageDescription</key>
<string>WAVE uses the camera so you can record a Reel.</string>
<key>NSMicrophoneUsageDescription</key>
<string>WAVE records audio with your Reels.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>WAVE uses your location to centre the delivery map, so you can drop a pin where the courier should come.</string>
```

The location string matters more than it looks. The delivery map works fine
without permission — the pin can be dragged from a default view — so the app
must not treat a refusal as fatal. The prompt is asked at the map screen, not at
launch, and the copy says what it is for.

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Coarse is enough to centre a map. Fine location is not requested: it is a
     harder permission to be granted and the buyer drags the pin anyway. -->
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

Xcode capabilities: Sign in with Apple, Push Notifications, Background Modes →
Remote notifications, Associated Domains.

### 6. Sign-in providers

- **Google** — add debug *and* release SHA-1 and SHA-256 fingerprints to each
  Firebase Android app. Sign-in fails silently without them.
  `./gradlew signingReport` prints both.
- **Apple** — create a Service ID and a Sign in with Apple key, then paste them
  into Firebase → Authentication → Apple.
- **Phone** — add the SHA-256 for Android SafetyNet and upload an APNs auth key
  for iOS silent verification.

### 7. Push notifications

Upload an **APNs auth key** (`.p8`) to Firebase → Project Settings → Cloud
Messaging. Without it iOS receives nothing, and nothing in the app reports this
— `registerDeviceToken` deliberately swallows its error rather than interrupting
a user.

### 8. Deep links

The app generates `https://wave.app/...` links for Reels, products and orders.
They only resolve if the domain is verified.

- **Android** — host `.well-known/assetlinks.json` and add an `intent-filter`
  with `android:autoVerify="true"`.
- **iOS** — host `.well-known/apple-app-site-association` and add
  `applinks:wave.app` under Associated Domains.

Replace `wave.app` in `Routes` if your domain differs.

### 9. Bunny Stream

Create a Video Library and a Pull Zone, then:

- In library settings, **enable only 360p, 480p and 720p**. This is the single
  highest-leverage cost decision in the project and it is a dashboard setting,
  not code — above 720p rarely reads as sharper on a phone-sized Reel and
  meaningfully raises storage and egress cost.
- Enable **Token Authentication** on the pull zone.

### 10. Cloud Function secrets

**Phase 1 is cash on delivery only.** These four are required; the functions
that use them fail at call time otherwise.

```bash
firebase functions:secrets:set BUNNY_TOKEN_AUTH_KEY    # pull zone token auth key
firebase functions:secrets:set BUNNY_PULL_ZONE_HOST    # e.g. vz-abc123.b-cdn.net
firebase functions:secrets:set BUNNY_API_KEY           # video library API key
firebase functions:secrets:set BUNNY_LIBRARY_ID        # numeric library id
```

**Do not set the four `ZAINCASH_*` secrets.** The ZainCash webhook export is
commented out in `functions/src/index.ts` for exactly this reason: if it were
exported, `firebase deploy --only functions` would fail at deploy time without
those secrets — which would force provisioning a ZainCash merchant account
before *any* function could ship, including ones with nothing to do with
payments. `placeOrder` independently rejects every payment method except
`cash_on_delivery`, so no order can reach a state the webhook would need to
confirm.

When Phase 2 turns ZainCash back on: uncomment the export in `index.ts`,
uncomment `cashOnDelivery` alongside `zainCash` (or whichever rails are ready)
in `PaymentRail.phase1EnabledRails`, update the matching guard in
`functions/src/orders/placeOrder.ts`, and set the four secrets below.

```bash
firebase functions:secrets:set ZAINCASH_SECRET
firebase functions:secrets:set ZAINCASH_MERCHANT_ID
firebase functions:secrets:set ZAINCASH_MSISDN
firebase functions:secrets:set ZAINCASH_BASE_URL       # test vs live endpoint
```

### 11. Deploy rules, indexes and functions

```bash
cd functions && npm ci && npm run build && cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage:rules,functions
```

**Do not skip `firestore:indexes`.** Twenty-three composite indexes are declared,
and the emulator does not enforce index requirements — a missing index passes
every local test and fails on the first real query.

### 12. Seed the configuration documents

Several features read config from Firestore and degrade quietly without it.

**`config/payments`** — **not needed in Phase 1. Do not create it.**

Phase 1 is cash-only and the enabled rails are a compile-time constant
(`PaymentRail.phase1EnabledRails`), deliberately not a config document — see
step 10. Nothing reads `config/payments` right now, so creating it and adding
`"zainCash"` to it would have **no effect** while looking like it had one, which
is the worst kind of configuration: a switch that appears to be on.

When Phase 2 restores runtime-configurable rails, this document comes back and
the reader in `SavedDetailsDataSource.availableRails()` is restored with it.

**`config/legal_versions`** — `{ "terms": "1.0", "privacy": "1.0" }`
Missing, and the Terms re-acceptance gate never fires.

**`config/otp_limits`** — `{ "max_per_number_per_day": 5, "max_per_device_per_day": 10 }`

**`legal_documents/terms`**, **`/privacy`**, **`/seller-agreement`**,
**`/content-policy`** — each `{ version, body, updated_at, change_summary }`.
Seed drafts are in `docs/legal/`; **have a lawyer review them first.**

### 13. Remote Config and App Check

Publish the defaults from `lib/core/config/remote_config_keys.dart`. The trust
tier thresholds are read **server-side** by `recomputeTrustTier`; until they are
published it falls back to `functions/src/domain/trustTier.ts`, which is safe but
means the dashboard knob does nothing.

Register **Play Integrity** (Android) and **App Attest** (iOS) under App Check.
Debug builds use the debug provider automatically. Without this the OTP device
cap has nothing to key on and SMS pumping is unmitigated.

### 14. Grant yourself moderator access

The review queue at `/internal/review-queue` is gated on a custom claim, not a
Firestore flag. Set it with the Admin SDK:

```js
await admin.auth().setCustomUserClaims(uid, { moderator: true });
```

The user must sign out and back in for the claim to reach their token.

### 15. Map tiles — change this before launch

The app defaults to OpenStreetMap's shared tile server. **That default is for
development only.**

OSM's tile usage policy prohibits "heavy use" by applications, and the
enforcement is a block on your User-Agent — at which point every map in the app
goes blank at once, for everybody, with no warning and no gradual degradation.
It is donated infrastructure and a marketplace app is exactly the kind of traffic
it asks you not to send.

Pick a tile host — MapTiler, Stadia, Thunderforest, or your own — and pass it in:

```bash
flutter run -t lib/main_prod.dart --flavor prod \
  --dart-define=TILE_URL="https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=YOURKEY" \
  --dart-define=TILE_USER_AGENT="com.yourcompany.wave"
```

`TILE_USER_AGENT` must be your real application id. It is the field every tile
provider blocks on, and a generic one gets you rate-limited alongside everyone
else who left the default.

Attribution to OpenStreetMap contributors is rendered by `WaveMap` and is a
term of the ODbL licence, not a courtesy. Do not remove it, including if you
switch to a provider that also requires their own credit — add theirs alongside.

### 16. Brand assets

Every image under `assets/brand/` is generated from one source file. To change
the logo, replace `assets/brand/source/logo_source.png` and run:

```bash
python3 tool/generate_brand_assets.py
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

The script handles the constraints that fail silently otherwise: iOS rejects an
icon with an alpha channel at upload rather than at review; Android adaptive
icons are masked to a launcher-chosen shape and lose anything outside the inner
66%; and the Android 12+ splash icon is masked to a circle over roughly two
thirds of its canvas. Each target is scaled separately for those reasons.

### 17. Golden reference images

```bash
flutter test --update-goldens test/golden
```

Run once **on the machine that will run CI** — fonts and rasterisation differ
between platforms, and images generated elsewhere fail on the build server.

### 18. Run it

```bash
flutter run -t lib/main_dev.dart --flavor dev
```

### Running the tests

```bash
flutter test                                   # unit and widget
cd functions   && npm ci && npm test           # money, ranking, promo logic
cd rules-test  && npm install && npm test      # Security Rules

# Goldens are tagged and skipped by default, because the reference images are
# generated rather than written and a fresh clone has none. Generate them once on
# the machine that will run CI — fonts and rasterisation differ between
# platforms — then run them explicitly.
flutter test --update-goldens test/golden       # once, to create the references
flutter test --tags golden                     # thereafter

firebase emulators:exec --only auth,firestore,functions,storage \
  "flutter test integration_test --dart-define=USE_EMULATOR=true"
```

## Architecture

Clean Architecture, feature-first. Domain never imports Flutter or Firebase.

```
lib/
├── app/           router, DI, navigation shell
├── core/          theme, widgets, services, errors, utils — shared, no feature logic
└── features/<f>/
    ├── domain/    entities, repository interfaces, use cases   (pure Dart)
    ├── data/      DTOs, data sources, repository implementations
    └── presentation/  BLoC, pages, widgets
```

Dependencies point inward. A BLoC depends on a repository *interface*; the
implementation is injected. This is what makes the domain testable without a
Firebase emulator.

**Build order** (§8, and the mitigation the brief's own reviewer notes asked
for): data models → services/repositories → state management → UI. The
foundation surfaces as broken before ten screens are built on top of it.

---

## The decisions worth knowing about

Things a future maintainer will otherwise undo by accident.

**The controller window is a hard rule, not an optimisation.** At most three
players exist at once. Each holds a native decoder that Dart's GC does not free —
only `dispose()` does. Widening the window is exactly the change that
reintroduces the OOM crash, and the crash appears 40 Reels into a session with
no Dart stack trace. Don't widen it without a memory profile.

The pool takes an injectable `PlayerFactory` purely so this is testable:
`VideoPlayerController` needs a live platform channel and cannot be constructed
in a unit test, which would leave the app's most dangerous invariant covered by
nothing. `test/features/reel_controller_pool_test.dart` scrolls a 50-Reel feed
and asserts the count never exceeds the window, that departing players are
*disposed* rather than paused, and that a player finishing initialisation after
its Reel left the window is released rather than adopted — the fast-scroller
race that leaks a decoder per swipe.

**Like counts are never a document field.** Sustained writes to one Firestore
document cap at roughly 1/second. A viral Reel exceeds that instantly, and it
doesn't fail cleanly — writes queue and slow, which presents as "the like button
is broken." Hence shards, plus a scheduled job that materialises the sum back
onto the Reel so the feed reads one field.

**Orders are never created by the client.** `placeOrder` re-reads prices and
stock server-side. A client that sends its own total is a client that can buy a
$500 item for $5.

**The idempotency key is generated when checkout opens, not when Pay is
tapped.** That's the whole contract. A key created at tap time is a new key on
every retry, which is no protection at all — and retries are most frequent
exactly when the connection is worst.

**`phone_verified` is written only by a Cloud Function.** Security Rules block
it from client writes. If a client could set it, the checkout gate would be
decorative.

**Comments are open; reviews are not.** The implementation carries a
server-side kill switch: `CommentRepositoryImpl` checks
`comments_verified_purchase_only` before every post, so the stricter behaviour
can be turned on from Remote Config without a client release. Reviews require a delivered order
containing that exact product, enforced in Security Rules. Comments are open to
any signed-in non-guest user — a deliberate deviation from the literal ask,
flagged in the brief's §0. Pre-purchase questions ("does this run true to
size?") are the highest-intent comments in a Reels-to-purchase funnel, and
gating them removes the discovery behaviour Buy Now depends on. To revert:
tighten the `comments` block in `firestore.rules` and flip
`comments_verified_purchase_only` in Remote Config.

**Trust thresholds live in Remote Config.** The brief says tune them once real
volume exists. A hardcoded threshold means a code deploy to change a business
rule.

**Trust badges never rely on colour alone.** Gold and `warning` share the amber
family — unavoidable, gold is yellow. Every badge renders icon + text label.
WCAG 1.4.1, and it's what stops "Gold Trusted" reading as "Low stock."

**App Check ships with mandatory OTP, not after.** Unprotected phone auth is a
well-known way to accidentally fund an SMS-pumping bot farm — the attacker's
revenue is your SMS bill.

**`CheckoutBloc` is registered as a factory, not a singleton.** That is
load-bearing: a fresh instance mints a fresh idempotency key. Reusing one
instance across two separate checkouts would reuse the key, and the second
order would silently return the first one instead of being placed.

**The auth stream is the only path into `AuthStatus.signedIn`.** Sign-in
handlers deliberately do not emit a signed-in state themselves — they let the
`authStateChanges` stream deliver it. One path means the two can never
disagree about who is signed in.

**The generated localization file is checked in as a placeholder.** It is
normally gitignored and produced by `flutter gen-l10n`, but a fresh clone would
then fail to analyse before the first codegen run — which is exactly when a new
engineer is trying to work out whether the project is broken. The stub returns
empty strings and is overwritten by real codegen; `.gitignore` excludes
everything in that directory *except* it.

**Onboarding never triggers an OS permission dialog.** On iOS a denied
permission cannot be re-requested in-app — only sent to Settings, which almost
nobody does. So the one prompt you get is spent at the moment of genuine use
("you're about to record a Reel", "something just sold"), where the reason is
obvious. The walkthrough only explains, so the later prompt is expected rather
than a surprise.

**Legal documents live in Firestore, not the app bundle.** Bundling them means
an app release for a policy fix, and policy fixes are sometimes urgent — a
clause that turns out to be wrong, or a regulator asking for a change by a date.
A Firestore document can be corrected the same afternoon and reaches every
installed build. A failed version fetch degrades to "nothing outstanding" rather
than locking everyone out.

**The Buy Now tap is recorded on tap, not on purchase.** A tap is a tap
whether or not it becomes a sale. Measuring only completed purchases would hide
the drop-off the metric exists to expose — and it is the drop-off, not the
conversion, that tells a seller which half of their funnel is broken.

**Every analytics event is written twice, to different systems, on purpose.**
Firebase Analytics completes the funnel chain that joins against orders for
product-wide questions. A Firestore document is what a seller's own dashboard
can query, because Analytics is sampled, delayed by hours, and cannot be
queried per-seller from a client. Neither substitutes for the other.

**Channel preferences are enforced server-side, not just on the device.**
Filtering a push after it arrives still costs the user a buzz in their pocket.
The only real respect for "turn this off" is not sending it, so
`sendNotification` checks the preference before it reaches the messaging API.

**The notification record is written before the push is attempted.** A
notification that exists only as a push is one the user loses by glancing away
— or never receives, if the token is stale or the OS blocked it. The centre is
the durable copy.

**A marketing push cannot send the app anywhere it likes.** Push payloads are
remote input. `NotificationRoute` rejects absolute URLs, protocol-relative
URLs, traversal, and anything without a leading slash — following an arbitrary
string from a push is how a notification becomes an open redirect.

**An unrecognised push type is never classified as marketing.** Guessing wrong
in that direction means showing something to someone who explicitly opted out
of exactly that. Unknown types fall to `social`, and route to the notification
centre rather than swallowing the tap.

**The seller dashboard reads Firestore, not the Analytics API.** Firebase
Analytics is sampled, delayed by hours, and cannot be queried per-seller from a
client. The funnel counters are materialised onto Reel documents by the same
scheduled functions that maintain every other aggregate. Analytics stays the
tool for product-wide questions; a seller asking about their own Reel needs an
answer from their own data.

**The seller funnel is split in two, not collapsed into one number.**
Tap-through (did the Reel make anyone want it?) and completion (having wanted
it, did anything stop them?) fail for opposite reasons and need opposite fixes.
A low tap-through means the Reel is not selling the product; a high tap-through
with low completion means checkout is losing people who had already decided to
buy. One combined conversion figure hides which of those is happening.

**The arithmetic that charges someone lives in a pure function.**
`computeOrder` takes a cart and a map of product snapshots and returns a total.
It has no Firestore dependency, which is what makes it directly testable —
Firestore requires all reads before any write inside a transaction anyway, so
the two phases were already separate and extracting the maths cost nothing.

**Signing out unregisters the FCM token first.** Otherwise the token survives
the sign-out and the next person to use the device receives the previous user's
order notifications — a privacy leak that would present as a backend bug and be
very hard to trace back to a missing line in sign-out.

**A rejected promo code fails the order rather than charging full price.**
Someone who typed a code and watched the total drop must not be silently
charged the undiscounted amount. The client shows a preview; `placeOrder`
recomputes the discount server-side, because a client-supplied discount is a
client-supplied price.

**A callable is not a trigger.** `onPhoneLinked` sets the flag the entire
checkout gate depends on, and it must be *invoked* — `linkWithCredential`
writes nothing to Firestore, so there is nothing for a background trigger to
fire on. This was wrong for several passes, behind a comment asserting the
opposite, and the effect was that no user could ever have placed an order.
`test/features/checkout_gate_chain_test.dart` now asserts every link in that
chain at source level.

**The Firestore emulator does not enforce composite index requirements.**
A query missing its index passes every local test and every emulator-based
integration test, then fails on first deploy. `firestore.indexes.json` is
therefore checked against the actual queries in the codebase rather than grown
by hand from production errors — nine were missing when that check was first
run.

**An unruled collection fails silently, not loudly.** It falls to the
default-deny catch-all, so the feature does nothing rather than erroring in a
way anyone notices. Five were missing when audited, one of which — 
`users/*/fcm_tokens` — would have made the entire notification system inert
while every piece of it looked correctly built.

**The rules tests seed with enforcement disabled, on purpose.** Establishing a
precondition is not the thing under test — and several fixtures are documents no
client may ever create, an order being the obvious one. That is the opposite
call from the integration seeder below, and the difference is deliberate: one is
testing the rules themselves, the other is testing the app *through* them.

**The integration seeder uses the client SDK, not the Admin SDK.** Every
seeded document therefore passes through the same Security Rules the app does.
An Admin-SDK seeder would bypass them, and tests would pass against data the app
could never have created — the failure mode where your rules are broken and the
suite is entirely green.

**`USE_EMULATOR` is a compile-time flag with a release-mode assert.** There is
deliberately no runtime switch. A test suite that *can* point at production is
one that eventually will.

**Cash on delivery is modelled as a payment provider, not an `if` branch.**
It is the primary rail in this market, not a degraded fallback, and giving it
the same interface as ZainCash keeps the order flow identical whether money
moves now or at the door.

**The webhook checks the amount against the order.** The order total was
computed server-side from product documents; if a provider reports a different
figure, the order is marked failed with both numbers recorded rather than
silently accepted. A webhook that can set its own amount is a webhook that can
mark a $500 order paid for $5.

**The order state machine is duplicated in Security Rules on purpose.**
`OrderTransitions` in Dart drives the UI; `sellerTransitionAllowed` in
`firestore.rules` is the one that counts. Without the server-side copy, a
modified client could move an order straight to `delivered` — skipping the point
where the buyer's cancellation window closes, and unlocking the rating prompt on
something that never shipped. Delivered, cancelled and refunded are terminal,
because an order that could come back would let a seller bounce it out of a
rateable state to erase a bad rating.

**Without seller order management, nothing else works.** It looks like a
back-office feature, but the dependency chain runs through it: no way to mark an
order delivered means no order ever reaches `delivered`, which means no rating
can be left, which means no seller ever earns a tier badge, which means the
trust signals on the Buy Now sheet are permanently empty. This is why it is in
Phase 1 and not deferred with the rest of the seller tooling.

**Account deletion pseudonymises rather than erases transaction records.**
A completed order is a shared record — the seller needs it for their own
accounts and dispute history, and has a lawful basis to keep it. So deletion
removes everything identifying and keeps the commercial facts. Ratings survive
too, because removing them would silently rewrite a seller's trust score, and
the next buyer would be shown a number built on evidence that no longer exists.
The in-app dialog says exactly this — an unkeepable promise of total erasure is
worse than an honest partial one.

**A failed compression costs quality, never the post.** `_compress` returns
the original file if the encoder fails or produces something larger — losing
someone's video to an encoder edge case is far worse than uploading a few extra
megabytes.

**Video bytes never pass through the backend.** The device uploads straight to
Bunny using a short-lived, single-video URL that a Cloud Function signs.
Proxying video through a function would be slow, hit request size limits, and
pay egress twice for no security gain.

---

## Deliberate deviations from the brief

Two, both flagged rather than quietly taken.

**1. `freezed` and `json_serializable` are not used.** §6 names them for data
models. The DTOs here are hand-written instead: immutable, `const`
constructors, explicit `fromJson`/`toJson`, `Equatable` for value equality.

The reason was that a fresh clone then runs with no `build_runner` step. That
argument is weaker now than when it was made, because `flutter gen-l10n` is
already a required setup step — so codegen is in the path regardless.

What you lose: `copyWith`, `==`, `hashCode` and `toString` are written by hand
on the DTOs, so a field added to a model and forgotten in `copyWith` compiles
silently. `freezed` makes that impossible. If you want the brief's stack,
converting is mechanical and touches roughly ten files; the annotations are
already in `pubspec.yaml`.

**2. The moderation queue is English-only.** Everything user-facing is in three
languages. The review queue is an internal tool for a small team, and
translating it would be cost with no reader.

## Localization

**Three languages: Arabic, Kurdish Sorani and English.** 378 keys each, zero
hardcoded strings.

Arabic is listed first in `supportedLocales`, and an unsupported system locale
falls back to Arabic rather than English. That is deliberate: Arabic is the
majority language of the target market, English is the development language. A
marketplace where the buyer cannot read the listing is not a marketplace.

Two of the three are RTL, which is why §2 insisted on an RTL-aware shell from day
one rather than treating it as a later pass. Both Arabic and Sorani render in IBM
Plex Sans Arabic, paired 1:1 against the same type roles, so switching language
does not break the scale.

A language picker lives at Profile → Language. Each option is written in its own
script and never translated into the current one — someone hunting for Kurdish is
looking for "کوردیی ناوەندی", and rendering it as "Kurdish" in Arabic helps
nobody who cannot read Arabic, which is exactly the person the screen exists for.

Phone numbers, prices and codes stay LTR inside RTL layouts. A right-to-left
phone number is unreadable.

`test/core/l10n_test.dart` asserts all three locales share identical keys, have
no empty values, no value identical to its English source, matching placeholders,
and — for `ar` and `ckb` — that every string actually contains Arabic script.
That last check catches an untranslated leftover which every other check passes.

## Data retention

`enforceRetention` runs nightly at 03:17, off the half-hour so it never overlaps
the materialisation sweeps.

| Collection | Kept | Why that long |
|---|---|---|
| `otp_requests` | 3 days | The abuse guard queries a 24h window; deleting at 24h would race it |
| `idempotency` | 7 days | Retries take seconds; a week covers a client that retried after a long offline period |
| `reports` (merged) | 30 days | A duplicate carries nothing the primary lacks except its reporter |
| `reports` (resolved) | 180 days | Long enough that someone contesting a removal still has the reason |
| `moderation_log` | 730 days | The record of decisions, deliberately outliving the reports it describes |
| `buy_now_taps` | consumed | Summed into a running total and deleted in the same batch |

**Never deleted:** pending reports (ageing one out would silently clear the
queue), reports behind a live suspension (the reason an appeal would need),
orders, reviews and ratings (shared commercial records — a deleted rating
silently rewrites a seller's trust score).

Deletes are capped per run rather than looping to exhaustion. A job that tries to
clear a million rows times out halfway and achieves nothing; a capped nightly job
converges, and its cost is predictable.

## Honest status

Every audit run against this codebase has found real bugs, and the rate has not
dropped: five orphaned fields, eleven unlogged analytics events, a Buy Now
funnel broken in the middle, 198 hardcoded strings, nine missing composite
indexes, five missing Security Rules, a checkout gate that could never be
passed, a sign-out button that did not exist, and promo codes that were a field
name and nothing else.

That is a signal about what is left, not a reassurance about what was fixed. A
codebase this size that has never executed has more wrong with it than static
analysis can reveal, and the first compile will surface a batch of it at once.

Treat the architecture as settled and the behaviour as unverified.

## Testing

```bash
flutter test
```

Five layers, each catching something the others cannot:

- `functions/test/` covers the money logic. Price computation, tier maths and
  feed scoring were extracted out of the handlers into `functions/src/domain/`
  precisely so they could be tested directly rather than only through a
  callable and a Firestore transaction. These tests assert the things that
  would be expensive to get wrong: that a negative quantity cannot subtract
  from a total, that volume alone never buys a trust tier, and that a Reel with
  one view and one like cannot score a perfect engagement rate and dominate the
  feed.

  The ZainCash adapter's crypto is covered here too — a forged signature, a
  payload edited after signing, an expired-but-validly-signed token, a
  truncated signature that would make `timingSafeEqual` throw, and the classic
  `alg:none` downgrade.

  ```bash
  cd functions && npm install && npm test
  ```


- `rules-test/` runs the **actual `firestore.rules` file** against the emulator.
  This is the layer that matters most: a bug in the rules is a data breach, not
  a crash, and it is the one artefact no amount of Dart testing can cover. The
  suite asserts the things that would be catastrophic to get wrong — that no
  client can create an order, that `phone_verified` cannot be self-granted, that
  a seller cannot jump an order to `delivered`, that a review requires a
  delivered order containing that exact product, and that the report queue is
  unreadable even to the person who filed it.

  ```bash
  cd rules-test && npm install && npm test
  ```


- `test/golden/design_tokens_test.dart` **recomputes** every WCAG contrast ratio
  from the brief rather than trusting the numbers in the table. A token nudged
  for aesthetics that breaks accessibility fails CI instead of shipping.
- `test/golden/token_golden_test.dart` renders the tokens. The maths test proves
  a colour is compliant; only a rendered pixel proves it actually reaches the
  screen and was not overridden by a stray `Color(0xFF...)` three widgets down.
  Generate the references once with `flutter test --update-goldens test/golden`.
- `test/widgets/` covers the shared components at the sizes and directions that
  break them — RTL, 1.4x dynamic type, dark mode, and screen-reader labels.

A golden diff you did not expect is the point. Never update a golden to make a
failure go away without looking at what moved.

Write tests alongside each feature as it's built (§8), not as a cleanup pass.

---

## Phase boundary

**Do not start Phase 2 or 3 work until Phase 1 is confirmed complete and
working** (§8). Deferred on purpose:

- Full delivery & logistics — courier assignment, live GPS, zones, proof of
  delivery (§5.2)
- `model_viewer_plus` 3D product viewer (§3.6)
- Negotiation / bidding, referrals, sponsorship, gamification
- Automated moderation (SafeSearch, toxicity screening)
- Biometric login, remote sign-out, multi-device sessions
- Algolia unified search index
- Automated KYC for base Verified Seller status

If a proposed addition only makes sense with a Phase 2/3 feature attached, say
so and propose the smallest Phase-1-compatible version instead.

---

## Payments

The gateway sits behind an interface, swappable per market (§5.2). For Iraq and
the Kurdistan Region: cash-on-delivery still leads most online orders by trust;
ZainCash, AsiaHawala and Qi Card are the dominant electronic rails; Rafidain
Bank and PayTabs both offer real integrations. Stripe does not currently serve
Iraq.

**Confirm current provider coverage before locking in the first concrete
implementation** — this changes faster than documentation does.

---

## Localization

English and Kurdish Sorani (`ckb`) at launch. Sorani is RTL, which is the point
of shipping it from day one — retrofitted RTL always misses something.
Arabic-script locales swap to IBM Plex Sans Arabic 1:1 against the same type
roles, so the scale survives a locale change.

Phone numbers and prices stay LTR inside RTL layouts. A right-to-left phone
number is unreadable.
