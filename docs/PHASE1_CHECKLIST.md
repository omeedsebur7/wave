# Phase 1 — completion checklist

Tracks every (P1) item in §1–§7 of the brief. `[x]` = implemented here,
`[~]` = scaffolded with the contract defined, `[ ]` = not started.

## §1 Authentication & Onboarding
- [x] Firebase Auth integration
- [x] Google Sign-In — repository + BLoC + wired button
- [x] Apple Sign-In — platform-conditional, required by App Store rules
- [x] Phone OTP — send, verify, and link-to-existing-account paths
- [x] Guest / browse-without-account mode, with in-place upgrade so a guest cart survives sign-up
- [x] Secure session handling / token refresh
- [x] Mandatory phone verification at first checkout
- [x] OTP abuse protection — App Check + client throttle + server cap
- [~] Account recovery flow (phone path works; email path pending)
- [x] First-run onboarding — persisted, skippable, routed, priming without prompting
- [x] Terms & Privacy acceptance + versioned re-acceptance gate + age confirmation

## §2 Navigation & Routing
- [x] 5-element bottom navigation with docked FAB
- [x] GoRouter with nested shell routes (per-tab stacks)
- [x] Deep linking (path constants centralised)
- [x] Graceful fallback route for invalid/expired links
- [x] RTL-aware navigation shell

## §3 Design System
- [x] Light + dark themes from a single-source ThemeExtension
- [x] All §3.2 colour tokens, contrast verified in CI
- [x] Typography incl. Arabic-script companion face
- [x] Glassmorphism / 3D surface tokens, 3 elevation tiers
- [x] Reduced-motion support, 48dp targets, Semantics labelling
- [x] Skeleton / shimmer loading states
- [x] §3.7 trust badge tokens + icon-and-label badge widget
- [x] Static product image as the launch default (3D viewer deferred to P2)

## §4 Social & Engagement
- [x] Publishing FAB + bottom sheet
- [x] Upload Reel — picker, real duration read, preview, product link, live progress
- [x] Reels: likes, views, save, infinite scroll
- [x] 60-second cap (enforced in Security Rules; client check pending)
- [x] Discovery & search — unified search screen across Products and Reels, sort, favourites
- [x] Marketplace grid, product detail + BLoC, reviews, favourites, follow/unfollow
- [x] Reviews — verified purchase only, 48h edit window
- [x] Comments — thread sheet, seller badge, rate limiting, Remote Config kill switch
- [x] Report / block (rules + entry points)
- [x] Notification Center, repository, FCM tokens, persisted preferences
- [x] Notification Preference Center
- [x] Anti-abuse rate limiting
- [x] Feed ranking heuristic

## §5 Commerce
- [x] Buy Now on Reel — button + quick-checkout sheet
- [x] Trust badge, buyer count and low-stock signal on the sheet
- [x] Buy-Now funnel analytics chain
- [x] Chat: repository, conversation list, thread view, offline send queue
- [x] Deep linking to Reels/products
- [x] Cart & checkout UI, address + payment pickers, saved-details reads
- [x] Checkout identity gate
- [x] 3-step order tracker, cancellation window, PDF receipt
- [x] Payment abstraction, rails config-driven, ZainCash + COD adapters
- [x] Idempotent payment & order writes
- [x] Verified-buyer seller ratings & trust tiers

## §6 Technical
- [x] Clean Architecture, feature-first
- [x] BLoC + GetIt/Injectable
- [x] Bunny Stream with server-side URL signing
- [x] Data Saver resolution cap
- [x] Paginated feed with prefetch
- [x] Bounded video-controller window
- [x] Sharded counters
- [x] Offline persistence
- [x] Security Rules + App Check
- [x] Force-update gate
- [x] Testing strategy — rules, functions, unit, widget, golden and integration layers
- [x] CI/CD — lint, unit tests, emulator integration job, flavored builds
- [x] Analytics taxonomy, Crashlytics, Performance Monitoring
- [x] dev/staging/prod flavors
- [x] Localization — 359 keys, both locales, zero hardcoded strings

## §7 Legal
- [x] Versioned Privacy/Terms acceptance
- [x] Account deletion — cascading function with honest pseudonymisation
- [x] Seller Agreement + Content Policy — seed drafts in docs/legal/  ·  [ ] legal review
- [x] Notification consent granularity


## Second pass additions

- Hand-written DI container — the app runs without a codegen step
- `AuthBloc` wired to routing, sign-in and the phone-verification gate
- `OrdersBloc` + streamed order detail with transactional cancellation
- `ProductDetailBloc` with parallel product/review/summary fetch
- `ReviewRepository` enforcing the delivered-order gate client-side
- Address and payment-method entities and pickers
- `ReelUploadService` + `createBunnyUploadSlot` / `bunnyVideoStatus` /
  `publishReel` functions
- `NotificationRepository` with per-device FCM tokens and topic mirroring
- Chat thread view with optimistic send and offline queue states
- 5 further test files (auth, idempotency, payment rails, upload, cart)

## Third pass additions

- **Comments** — the §4 feature the Reviewer Notes single out as a deliberate
  decision, now actually built: live thread sheet, seller badge on replies,
  optimistic posting with offline queue states, per-user rate limiting, and a
  Remote Config kill switch that flips to purchase-gated without a release
- **Seller profile** — the screen the trust-tier system exists to support.
  Evidence leads (tier, rating, delivered orders, time selling); a seller with
  no track record gets an honest line and a cash-on-delivery suggestion rather
  than a row of zeros
- **Saved addresses and payment methods** — real reads and writes, first
  address auto-defaults so the next checkout is genuinely one tap, available
  rails driven from a config document
- **Reel upload** — real `video_compress` pass and a streamed PUT to Bunny
  (streamed, because loading a 60-second video into memory is how mid-range
  Android devices die mid-upload)
- Chat list now opens threads; Reel action rail now opens comments and reports
- 2 further test files (comments, seller profile) — 16 total

## Fourth pass additions

- **§7 completed** — cascading account-deletion function that pseudonymises
  shared transaction records rather than pretending to erase them, a data-export
  function wired to the platform share sheet, and seed drafts of the Seller
  Agreement and Community Content Policy
- **PDF receipt** — generated on device so it works offline, laid out plainly
  because a receipt has to be legible printed in black and white, and honest
  about not being a tax invoice
- **Reel search** — §4 asked for search across Reels *and* Products; only
  Products had it. Both now use the same prefix approach, with the composite
  indexes and the `caption_lower` write on publish that make it work
- **Profile stat materialisation** — follower, product and rating counts
  recomputed by function rather than incremented by the client, because a
  client that can set its own follower count can fake reach
- **Favourites screen**, persisted notification preferences, chat bubbles
  aligned from real auth state
- 17 test files

## Fifth pass additions

- **Seller order management** — the queue, the transition state machine, and
  the Security Rules copy that enforces it server-side. This was the missing
  link in the whole trust system: without a way to mark an order delivered, no
  rating can ever be left and no tier badge can ever be earned
- **Unified search** — one screen across Products and Reels, run in parallel,
  with stale-response guarding and an empty state that names the real
  prefix-matching limitation instead of implying the catalogue is empty
- **Firestore rules** now cover both client-side order transitions (buyer
  cancel, seller advance), each locked to a specific set of writable fields
- 18 test files, including a full traversal test proving there is a legal path
  from `confirmed` to `delivered`

## Sixth pass additions

§6 names four testing layers. Three of them did not exist until now.

- **Widget tests** for the shared components, at the sizes and directions that
  actually break them: RTL, 1.4x dynamic type, dark mode, screen-reader labels.
  The trust-badge test asserts the icon-plus-label rule directly, since that is
  the only thing separating "Gold Trusted" from the amber "Low stock" warning
- **Golden tests** rendering both token sheets. The contrast test proves the
  maths; a golden proves the token reaches the screen and was not overridden
- **Integration tests** for the purchase and publish flows, written as
  executable specifications — every assertion spelled out, marked `skip`
  pending emulator seeding. They state what "works" means, which is the part
  worth getting right first
- **ZainCash adapter** behind the payment interface, with JWT signature
  verification using `timingSafeEqual`, plus a cash-on-delivery provider that
  shares the same interface rather than being an `if` branch
- **Webhook amount verification** — a provider reporting a different total than
  the server computed marks the order failed with both figures recorded
- Saved Reels grid, seller order queue linked from the profile
- 23 unit/widget/golden test files, 2 integration specs

## Seventh pass additions

- **The controller pool is finally testable.** It now takes an injectable
  `PlayerFactory`, because `VideoPlayerController` needs a live platform
  channel and cannot be built in a unit test — which had left the app's single
  most dangerous invariant covered by a file of `skip`s. The real tests scroll a
  50-Reel feed asserting the window never overflows, that departing players are
  *disposed* rather than paused, and that the fast-scroller race (a player
  finishing initialisation after its Reel left the window) releases rather than
  leaks
- **Emulator harness** — `EmulatorConfig` behind a compile-time flag with a
  release-mode assert, `TestSeed` fixtures that write through real Security
  Rules, and a CI job running `firebase emulators:exec`
- `seedDeliveredOrder` walks an order through the real seller state machine
  rather than writing `delivered` directly, because the client is forbidden from
  doing that — and exercises those transitions as a side effect

## Eighth pass additions

- **Security Rules test suite** (`rules-test/`) — the largest remaining
  untested surface, and the one where a bug is a data breach rather than a
  crash. 47 cases run the real `firestore.rules` against the emulator:

  - no client can create an order at any privilege level
  - `phone_verified`, `trust_tier`, `kyc_verified` and the rating aggregates
    cannot be self-granted — while ordinary profile edits still work, because a
    lock broad enough to block a name change is its own bug
  - a seller cannot jump an order straight to `delivered`, and `delivered` is
    terminal in both directions
  - neither party can smuggle a price change through a status update
  - a review requires a delivered order containing that exact product, so
    buying one thing does not license reviewing the whole catalogue
  - guests can browse and report, but cannot comment or publish
  - the report queue is unreadable even to its own author

- Each assertion was cross-checked against the rules file rather than assumed,
  and CI runs the suite as its own job

## Ninth pass additions

The Cloud Functions carry the money logic and had zero test coverage.

- **Pure domain modules extracted** — `computeOrder`, `tierFor`,
  `aggregateRatings` and `rankScore` moved out of the handlers into
  `functions/src/domain/`. The handlers now delegate. This is not tidying: the
  arithmetic that decides what someone is charged was previously only reachable
  by firing a callable inside a Firestore transaction
- **Order total tests** — a negative quantity cannot subtract from a total, a
  fractional one is rejected rather than rounded, NaN and Infinity are caught,
  an unknown product is not treated as free, and buying the exact remaining
  stock still works
- **Tier tests** — volume alone never buys a tier at any rating, thresholds are
  inclusive, corrupt ratings are dropped rather than clamped (clamping a 7 to a
  5 would silently inflate the average), and two sets sharing a mean produce
  different distributions
- **Ranking tests** — the 48-hour half-life is verified numerically, an old
  viral Reel cannot calcify the feed, a comment outweighs a like, and a Reel
  with one view and one like cannot score a perfect engagement rate
- All 15 deployable handlers confirmed registered in `index.ts`

## Tenth pass additions

- **ZainCash crypto tests.** The webhook signature check is the line between
  "a payment provider told us this order was paid" and "anyone did". Covered:
  a forged signature, a payload edited after signing, an expired token whose
  signature is still valid, a truncated signature (which would make
  `timingSafeEqual` throw rather than return 401), a malformed token, and the
  `alg:none` downgrade.

  Writing that last test found a real weakness: `alg:none` happened to fail,
  but only because our HMAC did not match — by accident rather than by design.
  An explicit HS256 check now makes it fail on purpose.

- **Seller analytics.** The funnel is deliberately split into tap-through and
  completion rather than reported as one conversion number, because the two
  halves fail for opposite reasons and need opposite fixes. Below ~100 views
  the screen says the percentages are unreliable instead of inviting someone to
  change something based on noise.

  The most actionable thing it surfaces is a well-watched Reel with no linked
  product — an audience that already exists with nothing to buy, where the fix
  is one tap.

## Eleventh pass additions

- **Push handling.** There was a `NotificationRepository` managing tokens and
  preferences, but nothing handling an actual message — so tapping a push did
  nothing. Now: a top-level background handler (it has to be top-level, or it
  works in the foreground and silently fails in the background, which is
  exactly when it matters), token-refresh re-registration, foreground
  suppression for channels the user turned off, and cold-start tap handling.

- **`NotificationRoute` as a pure function**, because notification routing only
  runs when someone taps a push, often from a cold start, on a device you do not
  have. Impossible to exercise by hand, trivial to test in isolation. It also
  treats push payloads as the remote input they are: a marketing path that is an
  absolute URL, protocol-relative, or contains traversal is rejected rather than
  followed.

- **Seller stats wired to real data.** The page previously took a null
  parameter. It now loads from `SellerStatsRepository`, backed by funnel
  counters a new scheduled function materialises onto Reel documents — with
  Security Rules making `buy_now_taps` append-only, because a seller who could
  delete taps could hide a Reel that converts badly.

- Revenue counts delivered orders only. Counting confirmed-but-undelivered
  money as earned shows a number that drops when a buyer cancels.

## Twelfth pass additions

The audit found six screens with no data connection. All six are now wired,
and the four remaining empty callbacks are gone.

- **Legal** — versioned documents loaded from Firestore, a re-acceptance gate
  that names what changed rather than saying "our terms have been updated", and
  a failure mode that degrades to "nothing outstanding" instead of locking
  everyone out of the app.
- **Force update** — launches the store URL from Remote Config, with a written
  fallback if the launch fails. The button never looks like it did nothing.
- **Notification centre** — streamed, marked read on tap rather than on render
  (marking everything read because the list was opened destroys the one signal
  telling someone what they have not seen), relative timestamps, deep links.
- **Onboarding** — persisted per install via SharedPreferences, gated in the
  router ahead of auth, always skippable, and deliberately never triggering an
  OS permission dialog.
- **Upload Reel** — picker, real duration read from the file rather than
  trusting the picker, looping preview, own-products-only link sheet, staged
  progress, and a back gesture blocked mid-upload.
- **List a product** — multi-photo strip with a cover marker, parallel uploads,
  and a price echo. That echo matters: IQD has no minor unit, so multiplying by
  100 would charge everyone a hundred times the price.
- The four dead buttons now either work or say honestly that the feature is
  Phase 2.

## Thirteenth pass — an audit for fields nothing writes

Ran a different check: which Firestore fields does the app READ that nothing
anywhere WRITES? It found five real bugs, two of which would have shipped as
visible breakage.

1. **Trust badges on product cards would have been permanently blank.** The
   seller's tier is denormalised onto product documents so a grid of twenty can
   draw twenty badges without twenty extra profile reads — but nothing ever
   copied it there. The whole tier system would have been invisible at exactly
   the moment a buyer is deciding. `recomputeTrustTier` now fans out to every
   listing and Reel, paged so a seller with thousands does not blow the batch
   limit.

2. **Every chat would have shown "Unknown".** The list read
   `participant_names`; `send()` never wrote it. Now written on every send, so
   a display-name change propagates without a migration.

3. **The consent checkboxes did nothing.** Terms acceptance and the age
   confirmation were collected on the sign-in screen and discarded. Now
   buffered through the repository and written on first sign-in — and never
   overwritten afterwards, so a later session cannot silently re-stamp an
   acceptance given against older terms.

4. **`reel_count` was always zero**, making an active seller look like they had
   never posted.

5. **Nothing sent notifications at all.** There was a repository, a push
   handler, routing, a preference centre — and no sender. Six triggers now
   exist, all going through one `sendNotification` that honours the channel
   preference server-side (filtering on the device still costs the user a buzz),
   writes the durable record before attempting the push, and prunes dead tokens
   — but only on the two error codes that mean gone-for-good, so a transient
   network failure never deletes a working token.

Order notifications fire on the three customer-facing stages only. Notifying on
every internal transition would mean a buzz for "packed" and another for "handed
to courier" — the exact over-notification the simplified tracker exists to
avoid.

## Fourteenth pass — two more audits, one serious bug

Applied the same "defined but never used" question to analytics events and
routes.

### The Buy Now funnel had a hole in the middle

§5.1 asks for the chain *Reel view → Buy Now tap → purchase completed*.
`reel_viewed` fired. `purchase_completed` fired. **`buy_now_tapped` never
fired at all.**

The consequence was larger than a missing metric: the seller dashboard's whole
tap-through half — the part that distinguishes "the Reel isn't selling the
product" from "checkout is losing people who already decided" — would have read
zero forever, and the `buy_now_taps` subcollection the scheduled function sums
would never have received a single document.

`BuyNowTracker` now writes to both places on tap, and deliberately on tap
rather than on completion: a tap is a tap whether or not it becomes a sale, and
measuring only completed purchases hides exactly the drop-off the metric exists
to expose.

### Ten other events were defined and never logged

Including three §6 names explicitly — review submissions, tracker-view rate,
and video time-to-first-frame. All 19 events in the taxonomy now fire.

Time-to-first-frame is measured inside the controller pool rather than the
widget, because the pool is the only place that sees the whole span: signing
the URL, opening the stream, and the decoder handshake. Measuring in the widget
would miss everything before the controller exists, which on a poor connection
is most of the wait.

### Three dead route constants removed

`splash`, `settings` and `publishSheet` named screens that do not exist or are
shown as sheets. A dead constant invites someone to navigate to a route that
silently falls through to the error page. The four that remain unreferenced are
path templates and the `errorBuilder` target, now documented as such so nobody
deletes them as unused.

## Fifteenth pass — the localization audit

Applied the same question to l10n, and it found the largest gap in the project.

**Before:** 43 ARB keys in two languages, the delegate never added to
`MaterialApp`, and **zero screens referencing a single key**. 98 hardcoded
English strings. Switching to Kurdish would have changed the text direction and
nothing else — every word still English, in an app whose stated target market
is Kurdistan and Iraq.

This is the "claimed but absent" category: §6 lists localization as a P1
requirement, the ARB files existed, and nothing connected them.

**Now:**

- The ARB pair covers **138 keys in both English and Kurdish Sorani**. The
  Sorani is written properly rather than left as TODOs — it is the part that
  genuinely needs care and is hardest to retrofit, and a file full of English
  placeholders would have looked complete while being worthless.
- `AppL10n.delegate` is registered in `MaterialApp`. Without that one line the
  ARB files are dead weight.
- `context.l10n.buyNow` via an extension, because a lookup that is tedious to
  type is one people skip, and every skipped lookup is a string that will never
  be translated.
- The generated file is **checked in as a placeholder**, with `.gitignore`
  excepting it. Otherwise a fresh clone fails to analyse before the first
  codegen run — precisely when a new engineer is deciding whether the project
  is broken.
- Six high-traffic surfaces converted: sign-in, phone verification, the nav
  shell, the order tracker, the trust badge, and Buy Now.
- **Five ARB integrity tests** guard the two ways localization rots invisibly:
  a key missing from one locale falls back silently, so the app looks fine to an
  English-speaking developer and is half-translated for the people it was
  translated for. The tests assert identical key sets, no empty values, no
  Kurdish value identical to its English source (bar the brand name and one
  loanword), matching placeholders, and plural metadata present.

**Honest state:** 37/138 keys wired, ~80 strings still hardcoded. Mechanical
work, not design work — but real work, and the README says so rather than
claiming the feature is done.

## Sixteenth pass — localization, second half

A stricter inventory found 198 hardcoded strings, not the 82 my first regex
caught. Converted the six largest surfaces, which between them carried the whole
purchase and fulfilment path.

- ARB grew from 138 to **189 keys**, both locales, Sorani written properly.
- **106 keys now wired across 11 files.** Everything a buyer touches between
  seeing a Reel and rating a delivered order is translated.
- The placeholder delegate is regenerated with **typed signatures derived from
  the ARB metadata**, so `coverPhotoNote(int)` and `orderNumber(String)`
  type-check identically before and after codegen. A stub with the wrong arity
  would compile today and break the moment `flutter gen-l10n` ran.
- `SellerOrderFilter` lost its `label` field. An enum constant cannot reach a
  `BuildContext`, so a label carried on the enum is guaranteed to be the one
  string on the screen that never translates. Labels are resolved at render.
- A new check asserts call-site arity matches ARB placeholder metadata — the
  mismatch that only appears after codegen replaces the stub.

Remaining: ~90 strings on secondary surfaces. The pattern is established; this
is now find-and-replace rather than judgement.

## Seventeenth pass — localization finished

198 → **0 hardcoded user-facing strings**. 359 keys, both locales, 41 files.

The last nine lived in three files with no `BuildContext`, and each needed a
different answer rather than a workaround:

- **`ReceiptService`** now takes a `ReceiptStrings` value object. A receipt is a
  document someone hands to a courier, a bank, or a tax office — generating it
  in the wrong language is worse than a mistranslated screen, because the
  person reading it cannot switch locale.
- **`DataExportService`** takes its share-sheet subject, which is the first
  thing a recipient sees.
- **`CartBloc`** emits a `CartMessage` enum. Reaching for a global locale from
  a BLoC would produce the wrong language the moment someone switches
  mid-session, and would make the BLoC untestable without a Flutter binding.

Four enums lost their label fields — `ReportReason`, `SellerOrderFilter`,
`NotificationChannel`, `PaymentRail`. This is the pattern most likely to be
missed by a localization pass, and the reason is structural: an enum constant
cannot reach a `BuildContext`, so any label living there is guaranteed to be the
one string on the screen that never translates.

`PaymentRail` kept a `brandName` for the branded providers. "ZainCash" is
ZainCash in every language; translating a provider name would make the option
unrecognisable next to that provider's own branding. Only the generic rails and
the descriptions are localized.

## Eighteenth pass — two infrastructure audits, two classes of silent failure

### Missing composite indexes (9)

Firestore requires a composite index whenever a query combines filters and an
orderBy across different fields. **The emulator does not enforce this.** Every
one of these queries passed local tests, would pass the integration suite, and
would fail on first deploy with "The query requires an index".

Found and added nine, covering the chat list, the seller dashboard, the feed
ranking sweep, the publish rate limiter, Buy-Now attribution, and the count
aggregations behind `reel_count` and `product_count` — a `count()` still needs
the index its filters imply.

Also added a structural check for the two query shapes Firestore rejects
outright regardless of indexes: more than one `array-contains`, and a range
filter whose field is not the first `orderBy`. Both currently clean.

### Missing Security Rules (5)

An unruled collection falls to the default-deny catch-all. Nothing fails
loudly — the feature simply does nothing, which is the hardest class of bug to
notice.

| Collection | What silently broke |
|---|---|
| `users/*/fcm_tokens` | **No push token ever stored — the entire notification system dead**, including the six triggers added two passes ago |
| `users/*/notifications` | Notification centre permanently empty; mark-as-read denied |
| `users/*/favourites` | Heart taps roll back; favourites page always empty |
| `users/*/following` | Follow button does nothing |
| `config` | Payment rails stuck on the cash-only fallback; **legal version check fails, so the Terms re-acceptance gate never fires** |

The `fcm_tokens` one is worth dwelling on: I built the repository, the push
handler, the routing, the preference centre and six sending triggers across
three passes, and the whole feature would have been inert because one rule block
was missing. Nothing in the Dart layer would have told me — `registerDeviceToken`
swallows its error, because a failed token registration is not something to
interrupt a user over.

Notifications are now read-only to their owner with `hasOnly(['read'])` on
update — a client that could create them could forge an "order delivered"
message to itself. FCM tokens are unreadable even by their owner: a token is a
delivery address, and the client never needs it back.

11 new rules tests, bringing the suite to 63.

## Nineteenth pass — the audit that found the worst bug yet

### Nobody could ever have placed an order

`onPhoneLinked` was exported from `index.ts` and **never called from Dart**.

That one line is the whole app:

1. `placeOrder` refuses unless `phone_verified === true`.
2. Security Rules forbid the client from writing `phone_verified` — correctly.
3. `onPhoneLinked` is the only thing that can set it.
4. It is an `onCall`, not a background trigger. `linkWithCredential` writes
   nothing to Firestore, so there was nothing for a trigger to fire on.

Therefore `phone_verified` could never become true, the checkout gate was
permanently shut, and **no user could ever complete a purchase** — in an app
whose stated core differentiator is Buy-Now-on-Reel.

What makes this worth dwelling on is the comment I had written above it:

> `phone_verified` is flipped by a Cloud Function triggered on this link

That was wrong, and it described the behaviour I intended rather than the
behaviour the code had. A reviewer reading it would have moved on. **The
comment was the thing hiding the bug.**

Both OTP paths now call it — linking a phone to an existing account, and
signing in with phone. Covering only the first would have left phone sign-in
users asked to verify the number they had just signed in with.

`test/features/checkout_gate_chain_test.dart` asserts all seven links at source
level. It is not a unit test of any one file, because the failure was not in
any one file — it was three files each being individually reasonable and
collectively wrong.

### Six Remote Config knobs did nothing

Declared as tunable, hardcoded in practice: feed page size, prefetch threshold,
shard count, Data Saver default, and the OTP caps. Someone tightening the OTP
cap during an abuse wave would have watched nothing happen.

All now read from Remote Config, each clamped so a bad value cannot break the
thing it configures — a page size of 1 stutters, a page of 100 defeats
pagination, an OTP cap of 0 locks everyone out of signing up.

### Server-side OTP limiting now actually exists

The client throttle is keyed by phone number and can only see one device. It
stops an accidental burst; it cannot stop SMS pumping, where an attacker cycles
numbers on a premium range they control and collects a share of the carrier fee.
Every request looks like a different plausible new user, and only the server
sees every device at once.

`checkOtpAllowance` caps by number and by App Check app ID, is called *before*
the SMS is requested rather than after, and records the attempt before sending
— over-counting costs one user a wait, under-counting costs an unbounded bill.
Both limits return the same message, because telling an attacker which cap they
hit tells them which axis to vary.

## Twentieth pass — "declared but never invoked", applied to three more places

The `onPhoneLinked` bug was a specific shape: something exists, looks correct,
and nothing calls it. Looking for that shape elsewhere found three more.

### No sign-out button existed

`SignOutRequested` was declared and handled; nothing dispatched it. There was
no way to log out of the app. On a shared phone — common in this market — that
is not a minor omission.

Worse: `unregisterDeviceToken()` was written, commented with exactly why it
mattered, and never called. So signing out (had it been possible) would have
left the FCM token registered, and **the next person to use the device would
have received the previous user's order notifications.** It now runs before
sign-out, while there is still a uid to find the token document under.

### Promo codes did not exist beyond a field name

§5.2 lists promo/coupon support as P1. What existed: a `promoCode` field on the
cart model, passed through checkout, and **ignored by `placeOrder`** — it was
not even destructured from the request. No entry field, no validation, no
discount.

Now implemented end to end: a pure `applyPromo` with 17 tests, a redemption
ledger enforcing one use per buyer, percentage and fixed codes, caps, minimums,
expiry, seller scoping, and Security Rules making codes readable but
unwritable.

Two decisions worth naming. The minimum is checked against the **subtotal**,
before the discount — checking after would let a code push an order below its
own minimum and still qualify. And a rejected code **fails the order** rather
than silently charging full price: someone who typed a code and watched the
total drop must not be charged the undiscounted amount without being told.

### One dead event removed

`OrderCancelRequested` duplicated logic the order detail screen already owns.
Two places to cancel an order is two places to get the "window closes at
handedToCourier" rule wrong, and a destructive action with two implementations
will eventually have two behaviours.

## Twenty-first pass — closing out

- `maxHeightForCurrentNetwork` was never called: the Data Saver cap (§6) had no
  effect and Bunny served the full ladder on cellular regardless. Now applied
  before the player opens the stream — a player already negotiating an adaptive
  ladder does not renegotiate downward on its own — and the signed-URL cache is
  keyed by resolution, or moving from wifi to cellular would serve the cached
  full-quality URL for the rest of the session.
- `AnalyticsService.screen` was never called: no screen views were recorded.
  Now reported from a single `NavigatorObserver`, keyed by route path with ids
  stripped, so a rename in code does not split a funnel and `/reels/abc` and
  `/reels/def` do not become two screens.
- Camera permission priming now runs before the picker, using the flag written
  for it three passes ago.
- The two half-hourly scheduled sweeps both wrote to every published Reel on
  the same cadence. Offset to :00/:30 and :10/:40, because overlapping sweeps
  contend on the same documents and `rankFeed` could otherwise read a
  half-updated funnel count and rank on it.
- Ten unused ARB keys removed, the rest wired; the app title now follows the
  locale via `onGenerateTitle`.
- Every unexplained `catch (_)` now states why it swallows.
- **All 13 skipped tests replaced with real bodies.** The integration suite
  exercises the data layer rather than driving widgets: the failures worth
  catching there — double-charging, a gate that can be skipped, stock going
  negative, a Reel published before it can play — live below the UI, and a
  widget-driven test would couple them to a button's position.

Phase 1 is complete to the limit of what can be written without running it.

## Twenty-third pass — auditing against the brief rather than my own checklist

Asked again whether Phase 1 was complete, I checked the brief's P1 list instead
of my checklist, which had drifted. Three findings.

### Reports were never written anywhere

The report sheet logged an analytics event and set `_submitted = true`. It never
wrote a document. So the confirmation screen — "a moderator will look at this" —
was untrue, and would have stayed untrue in production while the analytics
dashboard showed a healthy stream of reports being filed.

### There was no admin review queue

§4 asks for the report button *paired with a basic admin review queue*. The
`reports` collection was write-only with no reader at all. Now:

- A moderator queue at `/internal/review-queue`, gated on a custom token claim
  rather than a Firestore flag — a claim travels in the token, so Security Rules
  check it without a read, and a client cannot grant itself one.
- Sorted urgent first, then most-reported, then **oldest**. Oldest rather than
  newest because a newest-first queue leaves the bottom permanently unreviewed
  once volume exceeds capacity, which is precisely when review matters.
- `dedupeReport` folds repeat reports on one target into a single entry with a
  count. Eight people reporting the same Reel should be one queue item marked
  "8 reports", not eight items a moderator dismisses eight times.
- `resolveReport` applies the outcome and writes an append-only audit entry in
  the same batch. Content removal is a status change, never a delete — removed
  content still has to be visible to an appeal, and deleting it destroys the
  evidence the decision rested on.
- Rules pin a client-created report to `action: 'pending'` and
  `report_count: 1`. Without that, someone could file a report against
  themselves already marked dismissed and bury it before any moderator looked.
- The reporter's identity is never rendered in the queue. They were promised
  confidentiality, and a moderator who knows who reported whom can be lobbied.
- Even a moderator cannot write an outcome directly — that path would leave a
  decision with no audit entry naming who made it.

8 new rules tests, suite now 71.

### `freezed` is a real deviation, now flagged

§6 names `freezed` + `json_serializable`. Hand-written DTOs achieve the same
outcome but not with the named tools, and the original justification — no
codegen on a fresh clone — no longer holds now that `flutter gen-l10n` is a
required step. Documented in the README under *Deliberate deviations* with what
it costs, rather than left as an unremarked substitution.

## Twenty-fourth pass — recovering lost work, and two more enforcement gaps

A previous pass's output was not on disk when I next looked: the Arabic locale,
the language picker, account recovery, the rewritten README setup section and the
three-locale l10n test were all absent, and the package I had delivered contained
two locales rather than three. All rebuilt and re-verified against disk this
time, not against a check run several steps earlier.

The lesson is about my own tooling: the verification script reads files it assumes
exist, so when work vanishes several of its checks pass vacuously — the code
referencing the missing files vanished too. Existence is now asserted explicitly
before packaging.

### Suspension was a flag nothing read

`resolveReport` set `suspended: true` on a user document and **nothing anywhere
checked it**. A suspended account kept full write access.

Now enforced properly:

- A custom **token claim**, not just the Firestore field. The claim is what
  Security Rules check, and it costs no read on every write; the document is what
  the app reads to explain itself. Setting one without the other gives you a
  suspension that is either unenforceable or unexplainable.
- **Refresh tokens are revoked** on suspension. A claim otherwise reaches the
  device only on the next token refresh — up to an hour of a suspended account
  carrying on.
- Reads survive suspension deliberately. A suspended seller may have deliveries
  outstanding, and hiding those would strand the buyers waiting on them. They can
  also still read the policy they broke, which is the only route to an appeal
  that goes anywhere.
- `liftSuspension` is a separate callable, because reinstatement is an appeal
  outcome and does not belong to whichever report first triggered it.

### §4's server-side rate limits did not exist

The brief asks for comments, likes, follows and reports to be rate-limited
*server-side*. Only the upload slot and OTP paths had any server limit; the rest
relied on a client `RateLimiter`, which is a courtesy — anyone can call Firestore
directly with a stolen token.

Now a `rate_limits/{uid}` document, readable and writable only by its owner and
only to advance a timestamp to exactly `request.time`, so a cooldown cannot be
rewound. Rules check it via `cooledDown()`: 5s between comments, 2s between
follows, 30s between reports.

Two deliberate asymmetries. **Unfollowing is never throttled** — making it harder
to withdraw attention than to give it is the wrong asymmetry, and someone
rate-limited out of unfollowing an account they want away from has a worse problem
than the one the limit solves. And **likes are not throttled at all**: a like is
one document per user per Reel, so it is already idempotent and spamming it cannot
produce more than one row. Throttling it would cost a document read per like for
no protection.

## Twenty-fifth pass — blocking, offline, cold start

Same question as before: which fields does the app write and never read?

### Blocking did almost nothing

`blocks/{uid}/blocked/{id}` was written by the profile screen and read by the
profile screen. Nothing else consulted it. A blocked account's Reels stayed in
the feed, their listings stayed in search, their comments stayed under posts and
their conversation stayed in the chat list.

The report sheet meanwhile said, in three languages, "you will stop seeing their
posts and messages." That was untrue.

Now enforced at all four surfaces through one `BlockList` that streams the set and
exposes a synchronous answer — synchronous because the feed filters on every
emission, and awaiting a read there would either stall the list or flash
unfiltered content before hiding it, which defeats the point.

Filtering is client-side, and the limitation is documented rather than hidden:
Firestore has no efficient "not in this arbitrary list" operator, `whereNotIn`
caps at ten values and cannot combine with the ranked feed's ordering. So a
blocked author's Reel is fetched and dropped, consuming a slot in the page. That
is acceptable because block lists are short in practice; it would not be if they
were long, and the fix then is a materialised per-user feed — a Phase 2 scale
problem.

Two small decisions inside it. A **null author id is treated as visible, not
blocked** — that is malformed data, not a blocked person, and hiding it would
make a data bug present as a block, which is the harder of the two to diagnose.
And the block list **re-subscribes on auth state change**, or the previous user's
blocks would keep filtering the next user's feed on a shared device.

### No offline banner

§6 asks for one, and the reason is sharper than "show connection state":
Firestore queues writes offline and replays them on reconnect, so tapping "place
order" while offline *looks like it worked*. The write is real and pending and
nothing has reached a seller. The copy therefore names the consequence — "what
you do now is saved and will sync when you're back" — rather than the state,
which the user can already read off their signal bars.

### No cold-start trace

§6 names cold start and video time-to-first-frame. Only the second existed.

The trace now spans the first line of Dart to the first painted frame, completed
from a post-frame callback rather than after `runApp` returns — `runApp` returning
means the tree was described, not painted, and the gap between those is exactly
where a slow first build hides. Phases are attributes on one trace rather than
three separate traces, so one dashboard row shows where the time went.

Three new invariants added to `tool/check_project.py`, including blocking
coverage across all four surfaces, so this particular regression cannot recur
quietly.

## Twenty-sixth pass — data that grows forever

Six collections were append-only with no cleanup of any kind. Two of them were
worse than merely expensive.

### `buy_now_taps` had the wrong cost shape

One document per tap per Reel, and the funnel job ran `count()` over the whole
subcollection every thirty minutes. So the cost of *measuring* a Reel's success
rose with that success, indefinitely, whether or not anyone looked at the number.
A Reel that did well was a Reel that got permanently more expensive to report on.

It now consumes: sums new taps into a running total with `FieldValue.increment`
and deletes the documents it counted, **in one batch**. Separate operations would
either lose taps (deleted, not counted) or double-count them (counted, not
deleted) on a crash between the two. Batched, a crash before commit leaves the
taps in place for the next run — the safe direction to fail. Capped at 400 per
Reel per pass so one viral Reel cannot starve the other 1,999 in the sweep.

### `otp_requests` was read cost on a hot path

The OTP guard counts requests over a 24-hour window on every single request. Old
rows were not just storage — they were slowing down the query that protects
against SMS pumping, and the slowdown grew with every OTP ever sent.

### A retention policy, with stated exemptions

`enforceRetention` runs nightly at 03:17, deliberately off the half-hour so it
never overlaps the materialisation sweeps. Windows: OTP rows 3 days, idempotency
keys 7 days, merged duplicate reports 30 days, resolved reports 180 days, audit
log 730 days.

What it does **not** delete matters more than what it does:

- **Pending reports, ever.** An unreviewed report ageing out of the queue would
  silently clear it, which is the opposite of what a queue is for.
- **Reports that led to a suspension.** That is the decision most likely to be
  appealed months later, and the report carries the reason the audit entry does
  not.
- **Orders and reviews.** Shared commercial records; a deleted rating silently
  rewrites a seller's trust score.

Deletes are capped per run rather than looping to exhaustion. A job that tries to
delete a million rows times out halfway and leaves the collection unchanged next
time; a capped nightly job converges and its cost is predictable.

### Account deletion had drifted behind the schema

`rate_limits`, `buy_now_taps` and filed reports had all been added since the
cascade was written and none was cleared. Reports the user filed now leave with
them — except any that led to a suspension, which is pseudonymised instead,
because deleting it would remove the justification for an action still in force
against a third party.

### And a false positive in my own checker

The retention tests use `[^)]` inside a regex literal, which a naive delimiter
count reads as an unmatched paren. The checker now strips TypeScript strings,
template literals and regex literals — distinguishing a regex from a division
sign by the preceding token — and I verified against seven cases that it still
catches genuine imbalances rather than becoming permissive.

A checker that cries wolf on valid code is worse than no checker, because people
learn to ignore it.

## Twenty-seventh pass — the core conversion path was a placeholder

### Buy Now on a Reel did nothing

The quick checkout sheet — §5.1's "core differentiator", the shortest path
between watching and owning — was **entirely hardcoded**:

- a grey rectangle where the product image goes
- `const tier = TrustTier.gold` for every seller
- `const buyerCount = 214` for every product
- `const lowStock = true` always
- readiness fixed at `hasVerifiedPhone: false`, so the button always said
  "verify your phone" regardless of who was looking
- and the ready case: `() {/* place order with the sheet's idempotency key */}`

**The Buy Now button was a comment.** It survived several passes and three
rounds of direct questions about completeness, because every line in it was
individually plausible and there was no TODO to grep for.

Now backed by `QuickCheckoutCubit`: three parallel reads on open — product,
readiness, default address and payment — so the tap itself does no round-trips
before it starts. A one-tap purchase that fires two reads before it begins is not
one tap.

Details worth keeping:

- The idempotency key is generated when the sheet **opens**, and the cubit is a
  factory rather than a singleton — a reused instance would reuse the key across
  two different purchases.
- Defaults are the **first** saved address and method, not the most recent.
  Ordering by recency would send a one-tap purchase to whichever address someone
  last typed, which is exactly the surprise a one-tap flow cannot afford.
- If readiness and the saved details disagree, the order is **refused rather than
  guessed** — an order sent to an address nobody chose is worse than a refused
  tap.
- The button disables while placing. The key would deduplicate a double tap
  server-side anyway; not sending the second request is better than relying on
  the server to discard it.

### Two detector failures, both fixed

**`() {/* comment */}` is a dead button that `() {}` does not match.** The
checker now flags any callback whose body is empty after comment stripping, and
I verified it against five shapes to confirm it still passes real callbacks.

**Placeholder widgets now fail the build.** A widget with hardcoded literals and
a comment promising to wire it up later reads as finished code. The checker greps
`lib/` for the phrases that mark one.

### Referential integrity

`linked_product_id` was written on Reels and never cleaned up. A seller deleting
a listing left every linked Reel with a Buy Now button aimed at a document that
was gone — landing the failure on the people furthest along the funnel, the ones
who had already decided.

`unlinkDeletedProduct` and `unlinkWithdrawnProduct` clear the link on delete and
on moderation removal. The link is removed rather than the Reel: the video is the
seller's content and may be worth watching regardless, and only the promise of a
purchase is no longer true. A breadcrumb (`unlinked_product_id`, `unlinked_at`)
survives so support can answer a seller asking why their Buy Now button vanished.

## Twenty-eighth pass — money

Two bugs in `computeOrder`, both silent and both financial.

### Currency was overwritten, not checked

`currency = product.currency` ran on every line, so a cart mixing two currencies
took whichever product came last and summed the amounts as though they were the
same unit. 25,000 IQD plus 20 USD became "25,020" of something.

The single-seller rule made this unlikely rather than impossible — nothing stops
a seller listing in both. It now throws, and the test covers both orderings,
because a check that only compares against a running value passes in one
direction and fails in the other.

### No ceiling on an order total

Prices come from a document only the seller can write, so this is not defence
against a hostile client. It is defence against a typo: a seller who means 25,000
and types 25,000,000,000 should have the order refused rather than a buyer
charged.

`MAX_ORDER_MINOR` is one billion minor units — roughly USD 750,000 in IQD, far
above any plausible order and far below where JavaScript integers lose precision.
The gap between those two bounds is exactly where a fat-fingered price lands.

Checked per line *and* on the sum: each line can be plausible while the order is
not.

### The same bounds in Security Rules

Enforced on **create and update**. Bounding only create would catch the rarer
mistake and miss the common one — editing a price is routine, listing is not.

`sold_count` is now immutable to the client too. It drives the buyer count on the
Buy Now sheet, so a seller able to set it could manufacture social proof at the
exact moment someone is deciding whether to trust them.

### Sweeps that came back clean

Applied the Buy Now placeholder shape as a search: local `const`s holding domain
types, hardcoded counts and prices, pages with no data source, unreachable page
classes, uncalled sheet functions. Nothing further. The three "unwired" pages
flagged are genuinely static (a banner and two menus), and the four unreferenced
routes are the documented path templates and the `errorBuilder` target.

## Twenty-ninth pass — payment lifecycle

Started by auditing callable input validation and webhook security. The webhook
turned out to be well built — signature verification delegated to the provider,
replay protection keyed on the provider's event id, an amount check against the
server-computed total, 200 on duplicates so the provider stops retrying. But
pulling on it exposed four connected bugs.

### Retention pruned a collection that does not exist

The webhook ledger is `idempotency_keys`. Retention pruned `idempotency`. So the
job quietly did nothing while the real ledger grew forever — a name mismatch that
looks correct on both sides. The window is now 30 days rather than 7, because it
should be set by the slowest provider retry rather than the fastest client one: a
provider replaying a week-old event must still be deduplicated.

### A late webhook could resurrect a closed order

Nothing checked the order's current status before applying a payment result. A
`succeeded` event arriving after the buyer cancelled would set the order back to
`confirmed` — putting it in the seller's queue for something the buyer believes
they called off. On a delivered order it would reopen the cancellation window and
let the rating be erased.

Payment results now only apply to orders still awaiting payment. Refunds are
exempt, because they are late by nature and a refund on a delivered order is
exactly the case that has to work. A late event is **recorded** rather than
dropped — a provider reporting success on an order we already closed is a
reconciliation problem someone needs to see.

### Every order was confirmed regardless of payment

`placeOrder` set `status: "confirmed"` unconditionally. For cash on delivery that
is right — payment happens at the door. For an online payment it meant the order
entered the seller's queue to pack and ship **before any money moved**, and a
failed payment would then have to claw back something already sent.

### And two bugs my own fix created

Writing the guard, I tested for `awaitingPayment` — a status that does not exist
in the enum. It would have matched nothing and ignored every webhook. There is
now a checker invariant that every order-status string in the functions matches
the Dart enum, since these cross the language boundary as bare strings.

Then `pendingPayment` maps to `CustomerOrderStage.confirmed`, so an unpaid order
told the buyer the seller was preparing it, and — worse — **the seller's queue
filtered on the customer stage**, so the unpaid order landed in "to do" anyway,
defeating the entire fix.

The queue now filters on internal status. `CustomerOrderStage` is a deliberate
simplification for buyers; a seller needs the distinction it throws away. The
tracker keeps its three steps (§5.2) but the sentence underneath tells the truth
while payment settles.

## Thirtieth pass — a warning with no teeth

The seller cancellation dialog says, in three languages: *"Cancelling orders you
have already accepted affects your trust tier."*

It did not. `tierFor` read completed orders and average rating, nothing else. A
seller could accept and cancel half their orders and hold Gold, because rating
alone cannot catch it — **the buyer of a cancelled order usually never rates at
all**, so the average is built entirely from the half who received something.

That made the warning both false and toothless: the behaviour it exists to
discourage carried no consequence.

### The fulfilment gate

Applied before any tier is awarded. Below 85% of accepted orders actually
fulfilled, a seller is capped regardless of rating.

Four decisions inside it:

- **Capped at Bronze, not reset to newSeller.** Someone with 300 delivered orders
  and a bad patch is not a stranger, and pretending otherwise would erase real
  history a buyer should be able to see.
- **A sample floor of 10 accepted orders.** Below that, one out-of-stock
  discovery is noise rather than a pattern, and punishing it would make the tier
  measure inexperience instead of unreliability.
- **Buyer cancellations are counted separately and excluded.** A buyer changing
  their mind says nothing about the seller; folding them together would make the
  tier reflect luck.
- **The threshold is inclusive.** Exactly 85% passes. When a number is a
  published rule, the boundary is part of the rule.

### The attribution had to be locked first

`cancelled_by` decides which side a cancellation counts against, and both sides
could write it. A seller could cancel and record it as the buyer's, stepping
around the gate entirely — precisely the move it exists to measure. A buyer could
do the reverse and drag a seller's tier down for a change of mind.

Security Rules now pin the value to whoever is actually cancelling, on both
paths. The buyer path also writes the field at all, which it previously did not —
an order cancelled with no attribution is one nobody can explain later.

`seller_cancellations` is stored on the profile so the seller can see the number
the gate is reading. A tier that drops for reasons nobody can inspect is a tier
people distrust.

## Thirty-first pass — the promise audit, made permanent

The last two bugs both came from the same question: *does the app's copy match
what the code does?* So I swept every claim in the ARB against its
implementation.

Twelve claims checked. Eleven held — the 48-hour review edit window is enforced
in Security Rules with `request.time`, not just the repository; verified-purchase
reviews require `status == 'delivered'` server-side; no card number, CVV or
expiry exists anywhere in the codebase.

### The one that did not: "anything in your cart comes with you"

Technically true for the case it describes — the cart BLoC is a singleton, so a
guest upgrading mid-session keeps it. But the cart was **in-memory only** and did
not survive the OS killing the app, which on the low-end Android devices common
in this market happens constantly and without warning.

`CartStore` now persists it. Three decisions:

- **Local, not Firestore.** A cart is an intention, not a commitment. Syncing it
  would need a server-side identity a guest does not have, and every abandoned
  cart would become a document somebody pays to store and eventually has to
  garbage-collect.
- **Ids and quantities only, never prices.** A restored cart re-reads every
  product, so it shows what things cost now rather than a stale price someone
  might reasonably expect to be honoured. Quantities are clamped to current
  stock, so a cart holding five of something with two left does not fail at
  checkout with no explanation.
- **Fourteen-day expiry.** Older than that is not a shopping session, it is
  archaeology: items someone has forgotten wanting, at prices that have moved,
  from sellers who may have gone.

A corrupted entry is discarded and cleared rather than surfaced. Losing a cart is
a small annoyance; failing to open the app because of one is not.

### The audit itself is now a permanent check

Ten promises are pinned in `tool/check_project.py`, each paired with the code
that must be true for it. This lens has found more real bugs than any other check
in that file — blocking that blocked nothing, a moderator queue nobody could
read, a trust-tier warning with no consequence behind it.

Copy is a specification. It drifts silently because nobody diffs it against
behaviour, and it is the part of the product users actually rely on.

## Thirty-second pass — threat model

Worked through what a motivated seller or buyer could actually do. Most of it was
already blocked. Two things were not, and the first is the most serious
vulnerability found in the project.

### A seller could manufacture their own trust tier

**Self-purchase was allowed.** A seller could order their own product, become the
`buyer_id`, mark it delivered, and rate themselves five stars. With cash on
delivery no money moves at all, so it costs nothing. Repeat a hundred times and
you have Gold — the badge §5.1 describes as the thing that lets a stranger buy
from a stranger.

Every downstream control assumed buyer and seller were different people. The
review rule checks the author was the buyer; the rating rule checks the same.
Both were satisfied by a self-order, so the whole chain was sound and the
foundation was not.

`computeOrder` now refuses it, including when the self-bought item is hidden
among legitimate lines. Security Rules block self-review and self-rating
independently — those should be unreachable now, which is exactly why they are
asserted: one self-order predating the fix, or created by a future code path,
would otherwise mint a five-star review.

### Every signed-in account could read everyone's phone number

`users/{uid}` is readable by any signed-in user, because a seller page has to
show a name, photo, tier and rating to a stranger deciding whether to buy. The
verified phone number sat on that same document, and **Firestore cannot return a
subset of fields** — so the read that shows a rating also shows a phone number.

The number now lives in `users/{uid}/private/contact`, readable by its owner
alone. `phone_verified` stays public: it is a trust signal a buyer may reasonably
see, and it reveals nothing beyond "this account verified a number".

### Which broke the duplicate-number check, silently

One-number-one-account was enforced by querying `users` for `phone_number` — the
field I had just moved. The query would have returned nothing forever and let
every duplicate through, defeating the control that stops one phone farming
ratings across many accounts.

Replaced with a `phone_claims/{e164}` document written in a transaction. Two
reasons it is better than a fixed query: a query cannot see an uncommitted write,
so two simultaneous verifications of the same number would both find nothing and
both succeed; and a document keyed on the number makes uniqueness structural
rather than something a check has to remember to do.

The claim is released on account deletion, or the number would be burned — the
person could never re-register with it, and neither could whoever the carrier
later reassigns it to.

Both collections are function-only in both directions. `phone_claims` document
ids *are* phone numbers, so read access would hand over a directory of every
verified number in the system, and write access would let someone squat a number
they do not own and lock its real owner out permanently.

## Thirty-third pass — threat model, continued

Upload slots and chat came back clean: `publishReel` verifies the pending upload
belongs to the caller, and conversations check participant membership on both the
document and its messages. One real hole.

### Every promo code was one query away

`match /promo_codes/{code}` had `allow read: if signedIn()`. Firestore's read
permission covers **`list` as well as `get`** — so any signed-in account could
query the collection and walk away with every code in the system, including
campaign codes not yet launched.

The client never used it. Applying a code stored a string; `placeOrder` resolved
the discount server-side. The permission bought nothing and gave away everything.

Reads are now denied outright. Feedback on a mistyped code comes from
`validatePromoCode`, a callable capped at ten attempts an hour per person.

That is still an oracle — ask enough and you learn which codes exist — but a
callable can be rate-limited and a read rule cannot, and that is the whole
difference. Three design points inside it:

- **The throttle is keyed to the person, not the code.** Keying it to the code
  would let one attacker exhaust a popular code's budget and lock everyone else
  out, turning the anti-abuse measure into the abuse.
- **The attempt is recorded before the lookup.** A crash between the two should
  over-count rather than under-count: over-counting costs one person a wait,
  under-counting gives an unmetered guessing loop.
- **`not-found`, `inactive` and `exhausted` collapse to one answer.** Telling
  someone a code exists but is spent is far more useful to a guesser than telling
  them it never existed. The rejections that survive are the ones a buyer can act
  on — expired, already used, below the minimum.

A side benefit: a typo is now caught at entry rather than failing the order at
the last step, which was the right failure in the wrong place.

### And a fix to the checker itself

The promo check searched a 300-character window after the rule declaration — and
landed entirely inside the comment explaining it, so it failed on correct code.
Rule checks now run against a comment-stripped view of `firestore.rules`.

Heavily commented rules are worth having. A checker that cannot see past the
comments is not.

## Thirty-fourth pass — the four requested features

Two of the four were already built by earlier passes; two needed work. Worth
recording which, because the honest answer to "did you add this" differs per
item.

### 1. Price on the Buy Now button — added

The **sheet** button already carried a price. The **feed** button did not, and
that is the one that matters: it is the only price someone sees while scrolling,
and a tap that opens a sheet only to reveal an unaffordable price is a wasted tap
for the buyer and a false signal in the funnel.

The Reel now carries a denormalised `linked_product_price_minor`. Denormalised
because the feed renders three cards and prefetches more, so a read per card
multiplies the cost of scrolling — the same reasoning as the seller tier on
product cards.

That is only safe if something keeps it current, so `unlinkProduct.ts` gained a
price-sync trigger. A stale price means someone taps "Buy now · 25,000" and the
sheet says 40,000, which reads as a bait-and-switch even when it is an honest
edit. Nothing is ever charged from this number: the sheet re-reads the product
and `placeOrder` recomputes again.

**And a copy bug found while doing it.** The sheet's ready-state button said
"Confirm and buy · price" — and then opened a map. The button on that map said
the same words. By the rule the rest of that switch already follows (name the
step; people abandon at the surprise, not at the step), the sheet button now says
"Set delivery location · price".

### 2 and 3. OpenStreetMap and the location screen — already built

`flutter_map` against OSM tiles, a `LocationPickerPage` opened from the Buy Now
sheet, and `DeliveryLocationCard` on both the buyer's order detail and the
seller's queue. `placeOrder` persists the pin. ODbL attribution is part of the
map widget rather than something a screen can forget, and there is no Nominatim
geocoding at all — coordinates plus a landmark, which is what a courier here
actually uses.

**What was missing was operational.** None of it was in the README, so anyone
following the setup would ship on OSM's shared tile server. Their policy
prohibits application-scale use and enforces it by blocking the User-Agent — at
which point every map in the app goes blank at once, for everyone, with no
gradual degradation. Now step 15, plus a release-build warning logged to
Crashlytics, because discovering that from user reports is discovering it late.

Location permission strings were also absent. Coarse rather than fine: coarse is
enough to centre a map, is likelier to be granted, and the buyer drags the pin
regardless.

### 4. Logo and splash — assets generated

The config was already correct; the images were placeholders. `logo_source.png`
is now checked in and `tool/generate_brand_assets.py` derives all five outputs
from it.

Checking in derived images without the thing that produced them is how brand
assets rot — six months on, nobody knows which PNG was the master. The script
also encodes three constraints that fail silently: iOS rejects an icon with an
alpha channel **at upload**, not at review; Android adaptive icons are masked to
a launcher-chosen shape and lose anything outside the inner 66%; the Android 12+
splash icon is masked to a circle over two thirds of its canvas. The mark is
wide, so each target scales to a fraction of width and accepts vertical margin —
scaling to fill would make it illegible at 48dp.

Sign-in is now pinned dark. The mark is a glow whose halo is part of the
artwork; on a light surface it reads as a washed-out smear, and shipping a second
logo that is not the brand would be worse.

### And a checker gap the work exposed

`setDeliveryLocation` already existed as a bare app-bar title. Adding a
parameterised key of the same name silently changed its shape and broke the
existing call site. The arity check caught it, but only incidentally — there is
now an explicit check that a key has the same shape in every locale.

## Thirty-fifth pass — auditing the location feature

The map work was built in a pass that predates the audit lenses, so I ran them
over it. Validation, immutability and read access were all sound: the pin is
normalised server-side (including a Null Island check, because `Number(null)` is
0 and 0,0 is a real coordinate in the Atlantic), it is written by `placeOrder`
and never again, and only the buyer and seller can read the order carrying it.

### The pin survived account deletion

The cascade strips `delivery_address`. It does not strip `delivery_location` —
the pin was added afterwards and the cascade drifted behind the schema, the same
way it had drifted behind `rate_limits` and `buy_now_taps`.

So a deleted account left behind **the precise coordinates of somebody's home**,
on a record they had asked to be forgotten from, under copy promising addresses
were deleted for good. A more precise address than the text field beside it,
which was being deleted correctly.

### Fixed, but not by deleting everything immediately

Two people's interests point opposite ways here, and the split matters:

On a **finished** order the delivery details serve nobody — the parcel arrived,
and what remains is a home location on a record someone wants gone. Erased
immediately.

On an **in-flight** order a courier is holding a parcel. Erasing the address does
not protect the person, because the courier already has it; it strands the seller
with an order they cannot complete, and cancelling would count against their
fulfilment tier for something entirely outside their control. Kept, flagged, and
erased by the nightly sweep once the order goes terminal.

That makes the erasure window up to a day, so **the deletion copy now says so** —
in all three languages. A promise of immediate erasure that quietly holds an
address for another day is exactly the kind of drift the promise audit exists to
catch, and it would have been introduced by the fix itself.

### And a silent no-op in my own tooling

The checker edit that was supposed to guard all this **did nothing**. The guard
was `if 'delivery_location' not in s` — and that string was already in the file
from an unrelated check added a pass earlier, so the block was skipped while the
success message printed regardless.

Caught only because the check count stayed at 76. Edits now verify the file
actually changed rather than trusting that `.replace()` found its anchor, which
it silently does not when the surrounding code has moved.

## Thirty-sixth pass — things that silently do nothing, in Dart

Two Dart-specific bug classes, both invisible until they matter.

### Stream subscriptions

Three files had more `.listen()` calls than cancellations.

**`CartBloc` subscribed to its own `stream`.** A self-subscription is not
cancelled by `close()`, so it outlives the bloc — in tests that means writes
firing after close, and under hot reload two subscriptions both persisting. It
now overrides `onChange`, which is the intended hook and has nothing to cancel.

That change exposed a second bug in the same code: reading `state` inside
`onChange` returns the state being *replaced*, so persisting from it would always
have saved the cart as it was one change ago — and the last change before the OS
kills the app is precisely the one that matters. `onChange` now takes
`change.nextState` explicitly.

**`PushHandler` left its third subscription untracked**, so it could not be
cancelled. `start()` is also now idempotent: a handler registered twice shows
every push twice, and users report that as "the app is spamming me" rather than
as a duplicate subscription.

**The upload reader** was correctly self-cancelling on error, but if
`request.send()` threw — a dropped connection mid-upload, which on a mobile
network is the normal case rather than the exception — the file read carried on
to the end, holding a handle and feeding chunks into a sink nobody was draining.
Tens of megabytes read for nothing. Now cancelled in a `finally`.

### Analytics could report itself as a crash

`AnalyticsService.log` did not catch. Almost every call site is fire-and-forget —
nobody awaits a metric before showing a button — and an unawaited Future that
throws becomes an unhandled async error, which `bootstrap` routes to Crashlytics
as **fatal**.

So an uninitialised Firebase in a widget test, a dropped connection, or a
parameter the SDK rejects would be reported as a crash. Wrong twice over: it is
not a crash, and it corrupts the crash-free rate that decides whether a release
ships.

Fixed at the service rather than the dozen call sites, because the next call site
added would forget. Failures are recorded non-fatally so a silently broken
analytics pipeline is still visible, and the recording itself has a
`catchError` — if Crashlytics is what is failing, reporting the failure to
Crashlytics fails again.

`screen()` was the interesting case: it returned `logScreenView` directly, so
that one method stayed exposed while its neighbours were guarded. The test
asserts no method returns a raw Firebase future, which is the shape that let it
hide.

### And a test I threw away

The first version of the analytics test built a five-class indirection chain to
avoid importing `dart:io`, ending in `throw UnimplementedError()`. It would have
compiled and asserted nothing. `l10n_test.dart` next to it just imports
`dart:io`; the second version does the same in twelve lines.

## Thirty-seventh pass — tests that do not test, and a red-by-default suite

### `flutter test` failed on a fresh clone

Golden tests compare against reference PNGs that are **generated, not written** —
and they have to be generated on the machine that will run CI, because fonts and
rasterisation differ between platforms. So a fresh clone has no references and the
first `flutter test` anyone ran was red, for something they had not done.

That matters more than the inconvenience: a suite that is red by default is a
suite people stop reading, and once they stop reading it the real failures go
past too.

Goldens are now tagged and **skipped** rather than excluded, so the runner still
reports how many were skipped — silently omitting them would let someone believe
they had run and passed.

`design_tokens_test.dart` deliberately stays untagged despite living in the same
folder. It recomputes WCAG contrast ratios; it is arithmetic, not an image, and it
is the gate that stops an accessibility regression shipping.

### And my CI edit broke coverage

Inserting the golden step captured the existing `--coverage` flag, so coverage
began reporting from the golden run alone. Repaired, and the reasoning written
down: coverage comes from the logic run, because goldens exercise a rendering
pipeline and letting them into the number would inflate it with pixels.

There is now a check that CI never contains `--update-goldens`. A CI run that
regenerates its own references would make every golden test pass
unconditionally, forever, silently — and the check reads a comment-stripped view
of the workflow, because the comment warning about it says the same words. That
is the second time this session a check has matched its own explanation.

### Tests that assert nothing

Swept the suite for it, having nearly shipped one myself last pass — a five-class
indirection chain ending in `throw UnimplementedError()` that would have compiled
and asserted nothing.

The suite came back clean. My **detector** did not: it reported sixteen false
positives, because assertions legitimately live in local helpers like
`expectAtLeast` and in `expectLater`, and a per-test scan cannot see them without
a parser.

The permanent version counts assertions per **file** instead. Less precise, but a
file containing tests and no assertions at all is unambiguous, and a check that
cries wolf gets ignored — which was the lesson from the promo rule check two
passes ago and the regex-literal false positive before that.

It also fails on any `UnimplementedError` in the test tree, which is what my
discarded draft would have tripped.

## Thirty-eighth pass — secrets, and tests that could not build

### Three secret patterns were not gitignored

`google-services.json`, `GoogleService-Info.plist`, `firebase_options*.dart` and
`.env` were covered. Three were not, and one of them is the worst leak available:

**Admin service account keys.** Full Admin SDK access: bypasses every rule in
`firestore.rules`, reads every phone number and delivery pin, and can mint the
`moderator` and `suspended` claims. Nothing in this project's threat model
survives one being public. They arrive innocently — downloaded to run a script
against staging, left in the working directory under a name nobody chose.

**The Android keystore and `key.properties`.** The keystore *is* the app's
identity. Leaking it lets someone sign a build Android will install over the real
one as an update, and it cannot be rotated without publishing under a new package
name and losing every existing install. `key.properties` holds the passwords that
unlock it, which is why the two must never travel together.

Both now ignored, with a check that also scans the tree — `.gitignore` does not
untrack a file already committed, and by the time you notice, the fix is a
history rewrite and a key rotation.

Also checked and clean: no analytics parameter carries a phone number, address,
name or coordinate. Every event is logged as a Crashlytics breadcrumb, so a
parameter carrying PII would put it in crash reports — where it is retained, and
readable by anyone with console access.

### Three function tests could not have compiled

The source-reading tests added over the last few passes use `fs` and `__dirname`.
**`@types/node` was not a dependency.** `tsc` fails on both, so `npm run build`
and `npm test` would both have broken — and nothing caught it, because the
functions have never been compiled here either.

They also read source with a path relative to the process CWD. Jest happens to run
with `functions/` as its working directory, so it works today; run the suite from
the repo root and every one fails with ENOENT, looking like a code problem rather
than a path problem. Now anchored to `__dirname` behind one helper, so the reads
happen once at module load rather than three times per file.

### And a rename that corrupted its own documentation

Consolidating those reads, I renamed `source` to `RETENTION_SRC` with a blanket
regex — which rewrote the words inside the doc comment explaining the helper, and
inside four other comments. The comment ended up saying "reads a RETENTION_SRC
file relative to THIS file".

Caught by grepping for the new names inside comment lines. Worth recording as the
same mistake in a different costume: three times this session a blanket
`.replace()` has done something I did not intend, and every time the print
statement said it succeeded.

## Thirty-ninth pass — approximating the compiler

The TypeScript has never been compiled, and three build breaks had been found by
accident: a missing `@types/node`, a block-scoped variable referenced outside its
block, and a positional signature called as though it took an object. That is a
poor detection rate for something a compiler would catch instantly, so I wrote the
two checks that cover most of that class.

**Imported names against actual exports.** Resolves every relative import and
verifies each named binding is genuinely exported by the target module,
re-exports included. Clean.

**Call arity against declaration.** Clean, but only after three attempts, and the
attempts are the interesting part.

### `<` and `>` cannot be parsed with a regex

First version treated angle brackets as delimiters. Every `=>` decremented the
depth, so three `sendNotification` calls looked like they took three arguments.
Replacing `=>` fixed those and left `items.length > 1`, a bare comparison, doing
the same thing.

Dropping angle brackets entirely fixes comparisons and breaks generics —
`Map<string, number>` then hides a comma and a one-argument call counts as two.

They are genuinely ambiguous in TypeScript, and disambiguating them needs a
parser. The version I kept strips the shape that is *unambiguously* a generic — an
identifier immediately followed by angle brackets containing no operators — and
then treats `<` and `>` as ordinary characters. Both cases work.

### Self-tested before adoption, and then broken on purpose

Eight shapes: object literals, arrow arguments, generics, nested calls, bare
comparisons, and combinations. All correct before I would use the result.

Then I broke the code deliberately — an import that does not exist, and a call
with an extra argument — and confirmed both checks fired, before restoring and
re-running clean.

That step matters more than it sounds. Every check I have added this session
reported green immediately, and a check that has only ever been green is
indistinguishable from a check that cannot fail. Three of my own checks this
session have been silently broken: one matched its own comment, one had a window
too small to see the rule, one was skipped by a guard that was already true. None
of those were visible from a passing run.

## Fortieth pass — testing the tests

Ninety-one checks guard this codebase and every one of them had only ever been
green. That is not evidence they work; a check that has never failed is
indistinguishable from a check that *cannot* fail.

`tool/verify_checks.py` breaks one invariant at a time in the smallest way that
should be caught, asserts the intended check turns red, restores the file, and
confirms the suite is green again. Fifteen mutations, chosen where failure would
be expensive and silent: money, identity, permissions, secrets.

**Six of the fifteen went undetected on the first run.**

### Two were the harness's fault

`false /* isBlocked removed */` and `# serviceAccount pattern removed` both left
the searched token in the file, so the mutation changed nothing and the check
correctly stayed green. The checks looked weak; the harness was broken.

A harness producing false alarms is as useless as a check that cannot fail, so it
now refuses any mutation whose replacement still contains the token it removes —
with an explicit exemption for the two that legitimately *add* a permission
rather than removing one.

### Four checks were genuinely weak, all for related reasons

- **A mention is not a declaration.** Renaming `MAX_ORDER_MINOR` left its call
  sites referring to it, so a substring check passed on code that no longer
  compiles. Now matches the declaration.
- **Substring matching on identifiers.** `notSuspended` is a substring of
  `notSuspendedUnused`, so renaming the function out of use kept the check green.
- **A deny existing is not an allow being absent.** The promo check asserted a
  denial was present, which says nothing about an `allow read` added beside it.
  Firestore takes the union of matching rules, so one grant anywhere in the block
  grants it regardless of how many denials sit alongside. Now parses every grant
  in the block.
- **The checker crashed instead of reporting.** A missing translation key raised
  `KeyError` three checks after the one that had correctly detected it — and
  because results print at the end, the whole run was lost. Output was a
  traceback naming no invariant.

### The strengthened check immediately found a real bug

Requiring `notSuspended()` to be *called* rather than merely declared turned the
suspension check red — because **it was never called**. `isRealUser()` did not
include it and `isSelfWritable()` did not exist. The entire suspension
enforcement built in the twenty-fifth pass was inert: a suspended account could
write freely, while a rules test asserting otherwise sat unrun.

Another silent `.replace()` no-op, and the fourth this session. It survived
because the check I wrote to catch it was satisfied by the declaration alone.

Now folded into `isRealUser()` rather than added per call site, so a rule written
next year inherits the check instead of forgetting it. Reads still survive
suspension — a suspended seller needs to see outstanding orders, and hiding them
would strand the buyers waiting on deliveries. Favourites survive too: being
suspended should stop you affecting other people, not stop you using your own
bookmarks.

### Structural fix

`check_project.py` now wraps checks so an exception becomes a FAIL carrying the
exception text, rather than killing the run and discarding every result gathered
so far. A tool that dies on bad input is a tool people stop trusting on exactly
the inputs it exists for.

The harness runs in CI, because the failure it guards against is silent by
construction.

## Forty-first pass — cash on delivery only

Explicit product decision: Phase 1 ships cash-only. ZainCash is **paused, not
deleted** — the adapter, its signature verification, the webhook's replay
protection and all its tests stay in the tree, because Phase 2 turning a rail
back on should be a reviewable diff rather than a rebuild of the payment
abstraction.

### The boundary is the server, not the picker

`placeOrder` previously accepted **any string** as `paymentMethodId` and only
special-cased `"cash_on_delivery"` when choosing the order status. The client
picker offered nothing else, but a picker is a suggestion. Anyone calling the
callable directly — a modified build, a replayed request, a later regression
that widens the picker — could have created a real order with a real stock
decrement and a real seller notification, sitting in `pendingPayment` forever
because no webhook exists this phase to confirm it.

It now rejects anything but cash before the transaction opens. That check is the
boundary; the rail list in the UI is a courtesy.

### Enforcement in code, not config

`PaymentRail.phase1EnabledRails` is a compile-time constant, and
`availableRails()` now reads it instead of the `config/payments` Firestore
document.

That is a deliberate downgrade in flexibility. A dashboard document is exactly
the kind of thing a typo or a stale cache re-enables by accident, and
"we accidentally took an online payment during the cash-only phase" is a far
worse failure than "leaving Phase 1 needs a release". The one-line change lives
in code, gets reviewed, and ships — which is the point, not a limitation.

### The webhook export is commented out, and that matters at deploy time

`paymentWebhook` declares four `ZAINCASH_*` secrets in its `secrets: [...]`
config. Firebase fails `deploy --only functions` if a declared secret is unset —
for the **whole deployment**, not just that function. Exporting it would have
forced provisioning a ZainCash merchant account before *any* function could
ship, including ones with nothing to do with payments.

The README said "all eight secrets are required". Now four, with an explicit
instruction not to set the ZainCash ones yet and a note on what to change when
Phase 2 arrives.

### Three UI defects that only appear with one rail

- The picker drew an **unconditional `Divider`** before the "add a payment
  method" section. With cash as the only rail that loop yields nothing, leaving
  a horizontal line hanging under the last item — which reads as a rendering
  bug, not a short list.
- `cardDetailsNote` ("Card details are held by the payment provider, never by
  WAVE") rendered unconditionally. On a cash-only sheet it reassures about a
  thing that cannot happen and implies a capability the app lacks, which costs
  trust rather than building it.
- The sheet opened at all. Asking "How do you want to pay?" and offering one
  answer is a wasted tap on the core conversion path. Checkout now selects the
  single option directly — expressed as a general "exactly one choice"
  condition, so it stays correct when Phase 2 adds rails and for a returning
  buyer with one saved method.

### And the same weak-check mistake, twice

The invariant I wrote for the new guard tested for the mere presence of the
substring `PHASE_1_ALLOWED_PAYMENT_METHODS` — the identical "a mention is not a
declaration" flaw already found and fixed for `MAX_ORDER_MINOR` earlier in this
session. Renaming the declaration leaves the usage line containing the string,
so the check stayed green on code that could not compile.

Caught by the mutation harness, not by review. Fixed to match the declaration.
Three new mutations now cover the cash-only guards: all 18 detected.

## Forty-second pass — the detector's blind spot, and 26 strings behind it

Two dead-config consequences of the cash-only change, then a much larger find
that the change happened to expose.

### `config/payments` became a switch that looks on but is off

Making `availableRails()` read a compile-time constant left nothing reading
`config/payments` — while the README still told operators to create it and to
"add `zainCash` once your merchant account is live". Following that instruction
would have had **no effect while appearing to have one**, which is the worst
possible configuration state. The step now says explicitly not to create it, and
why.

### `pendingPayment` is now unreachable

Cash confirms immediately and every other method is rejected before the
transaction, so no order can enter a payment state this phase. Those branches are
kept and translated rather than deleted — an untranslated branch is exactly what
ships when Phase 2 makes it reachable again.

### The hardcoded-string check had a blind spot worth 26 strings

Looking at the seller order screen, I found ten English labels — `'Waiting for
payment'`, `'New — needs packing'` — on the screen sellers use more than any
other. The check that is supposed to catch this reported clean.

The pattern only matched strings in **widget-parameter position**: inside
`Text(...)`, after `label:`, `title:`, `hintText:`. A bare literal returned from a
`switch` arm — `OrderInternalStatus.packed => 'Packed',` — matched nothing.

Widening it to catch enum-dispatch arms found **26 hardcoded strings across five
files**:

- 10 seller-facing order status labels
- 7 upload progress stages, including the one that tells someone they can leave
  the screen during processing
- 5 seller action buttons — the most-tapped controls in the seller experience
- 4 marketplace sort options
- 2 rating prompts with the seller's name interpolated by string concatenation,
  which also assumed English word order around a name

Deliberately restricted to arms that look like enum dispatch. A lone
`=> 'value'` is more often a key, an asset path or a debug tag, and flagging
those would make the check noisy — and a noisy check gets ignored, which is
precisely how these 26 survived.

### The same structural trap, three more times

`ProductSort.label`, `ReelUploadProgress.label` and
`OrderTransitions.actionLabel` were the fifth, sixth and seventh instances of a
label defined next to its value in a layer with no `BuildContext`. It reads as
good cohesion and is the single most reliable way to make a string permanently
English.

Each is now resolved in the presentation layer. `orderActionLabel` also dropped a
`_ => to.name` fallback that would have rendered a raw enum identifier —
`handedToCourier` — to a seller if a transition were added without a label; it is
exhaustive now, so that omission is a compile error instead.

Brand names (`ZainCash`, `AsiaHawala`, `Qi Card`) are recorded as explicit
exceptions. Translating a payment provider's name would make the option
unrecognisable beside the provider's own branding, which is the one thing a
payment option cannot afford to be.

429 keys × 3 locales. The widened detector was then broken on purpose to confirm
it catches the switch-arm shape, and all 18 mutations still pass.

## Forty-third pass — closing the theme, permanently

Last pass found the same trap seven times by accident, one file at a time. Two
things followed from that: a systematic sweep for any remaining instance, and a
permanent check so an eighth cannot ship unnoticed.

### The sweep

Searched every `String get`/method named like display text
(`*label*`, `*title*`, `*description*`, `*message*`, `*name*`) that returns a
literal, in a file with no `context.l10n` reachable. One hit:
`PaymentRail.brandName` — the already-documented, deliberate exception for
provider names that must stay untranslated beside the provider's own branding.

Confirmed the pattern was not simply too narrow to find anything: re-ran it
against reconstructions of all seven fixed shapes (a `switch`-based `label`
getter, a `brandName`-style getter, a parameterised `actionLabel` method) and it
caught every one.

### The permanent check

`check_project.py` now flags any display-text-named getter or method returning a
literal outside a `_text.dart` resolver or a file with `context.l10n` in reach.
Matched on **name**, not on the trap itself — "no `BuildContext` reachable" is not
something a regex can determine when a context could arrive through a
constructor parameter or an outer closure, and every real instance found this
session used one of five naming patterns. That is a strong enough prior in this
codebase to be worth the false-negative risk of a name that dodges the
convention.

Two things the resolver files rely on, made explicit here: `_text.dart` is now a
naming *convention* the check depends on, not just a tidy suffix — it is how the
check tells a legitimate resolver from a repeat of the trap without opening the
file, which is also how a human skimming the tree tells them apart.

Verified three ways before trusting it:

1. **Ran clean** against the current tree — no unknown eighth instance.
2. **Detected a synthetic trap** injected into a file it had never seen
   (`Reel`, unrelated to any of the seven fixes), proving it generalises rather
   than being tuned to known cases.
3. **Confirmed zero false positives** on the three legitimate resolvers and on
   `PaymentRail.brandName`.

Registered as the harness's 19th mutation — reverting `ProductSort` to its
original broken shape, in the file where the trap actually lived — because a
check that has only ever been run by hand is not yet a check that is trusted.
All 19 now pass.

## Forty-fourth pass — a race this codebase had never actually tested

Returned to a systematic lens rather than an accidental find: concurrency.
Audited every `runTransaction` in the functions for read-then-write races.

### The transactions themselves are sound

All four (`placeOrder`, `resolveReport`'s dedupe, `onPhoneLinked`'s claim, the
payment webhook) read through `tx.get` before writing, which is what makes
Firestore detect a conflicting concurrent write and retry the transaction rather
than silently overwriting it. Stock decrements use `FieldValue.increment`, an
atomic server-side operation, not a read-modify-write in application code. This
is correctly built.

### But nothing had ever exercised it under real concurrency

Every existing test either checks the pure `computeOrder` function in isolation
— which cannot see a transaction-level race by construction — or fires the
*same* buyer's request twice, sequentially, to prove idempotency. Nothing had
ever put two different people against one unit of stock at the same instant,
despite that being one of the most consequential and ordinary races a
marketplace faces: two people tapping Buy Now on the last item of something
popular is a normal Tuesday, not an edge case.

### Why the existing harness could not express this

`TestSeed.signInReadyBuyer()` signs in on the single, shared
`FirebaseAuth.instance` every other helper assumes. Calling it twice does not
create a second buyer — it replaces the first, because a client SDK's auth state
is exactly the thing it assumes is singular. There was no way to represent "two
people, right now" with the existing helper at all.

`TestSeed.signInSecondBuyer()` opens a second, independent `FirebaseApp` —
its own auth, Firestore, and Functions client — wired to the same emulator
suite, so the two identities are as separate as two different phones. The two
`placeOrder` calls are fired through `Future.wait`, not sequential awaits,
because two sequential calls would let the first transaction fully commit before
the second even started reading — testing a lock, not a race.

### A mistake caught before it could fail silently

The first draft of the second-buyer helper had `markPhoneVerified()` call the
`onPhoneLinked` *client callable* — which does not work this way even for the
primary buyer; the real mechanism, used by every existing test, is a raw REST
patch against the Firestore emulator's admin endpoint, independent of any client
SDK session. Reading `TestSeed._adminPatch` before trusting my own addition
caught this: the correct fix was to delete the duplicate method entirely, since
`_adminPatch` needs only a `uid` and the outer seed's existing
`markPhoneVerified(uid)` already works unmodified for a second buyer.

The same review caught a second, quieter bug: the helper hardcoded
`'localhost'` for the emulator host, while `_adminPatch` in the same file reads
`EMULATOR_HOST` specifically because Android emulators reach the host machine on
`10.0.2.2`. Hardcoding `localhost` would have connected correctly on a desktop
test run and silently failed on Android — passing in CI and breaking on the one
platform nobody happened to test it on next. Fixed to share
`EmulatorConfig`'s ports and host resolution rather than repeating either.

### What the new test asserts

Two buyers, one unit of stock, fired concurrently. Exactly one order must
succeed — not zero, and not both. The loser's error must name the actual reason
(`is out of stock`) rather than surfacing as some unrelated failure that makes a
race look like a broken checkout. And the ledger is checked independently of the
per-call results: one order recorded, stock at exactly zero, never negative —
because a transaction that retried but left stock decremented twice would pass
"exactly one succeeded" and still be a real bug.

### What this pass could not do

This environment has no `firebase` CLI and cannot run the emulator suite, so the
new test has been verified statically — balanced delimiters, matching return
types across both `placeOrder` overloads, the exact error string confirmed
against `orderTotals.ts` rather than assumed, port and host configuration
matched against the app's real emulator wiring — but **not executed**. The
concurrency behaviour this test targets is exactly the kind of thing that can
look correct in code and still be wrong in practice; first compile and a real
emulator run remain the step that actually proves it, same as everything else on
the "cannot verify from here" list.

## Forty-fifth pass — a real race in moderation, and repeating my own mistake
## a third time while guarding against it

Continued the concurrency lens from the previous pass into moderation, a
different subsystem with its own transaction logic that had never been
examined this way.

### `resolveReport` had the exact bug its own comment warned about

It read a report's `pending` status through a plain `.get()`, branched the
entire function on that value, and only committed the decision roughly eighty
lines later — through an unconditional `WriteBatch` with no re-check. A comment
beside the original read said the double-resolution race was "worth losing
loudly," which is worse than no comment: it shows the author had identified the
exact danger and had not actually closed it. A batch commits unconditionally,
so two moderators acting on the same report within that window would both pass
the `pending` check and both proceed.

The audit log made the failure mode actively deceptive rather than merely lossy.
It allocates a new document per call — `.doc()` with no fixed id — so a lost
race would still produce a log entry for the decision that did **not** stick.
Whoever's write landed last would silently overwrite the other's decision on the
report itself, while the log showed both actions took place. An audit trail
that misrepresents which decision is the one that actually held is worse than no
audit trail, because it looks authoritative to whoever reads it later.

### The fix, and the one real constraint that shaped it

The whole read-check-write sequence now lives inside `db.runTransaction`,
including converting `resolveOwner`'s internal reads to use the transaction
handle — a read outside `tx` inside a transactional function is invisible to
Firestore's conflict detection and would silently reopen the exact race, while
looking identical to correct code at a glance.

The two Admin Auth calls (`setCustomUserClaims`, `revokeRefreshTokens`)
deliberately stay **outside** the transaction. Firestore can retry a transaction
body on conflict, and an Auth API call is not something Firestore can roll back
or safely re-run — calling it inside the transaction risked it firing twice on a
single logical resolution.

### New integration coverage, with an honestly-flagged gap

Building test coverage needed a capability the harness didn't have: a second,
independent *moderator* identity, generalizing the second-buyer pattern proven
in the previous pass. That meant granting the `moderator` custom claim through
the Auth emulator's admin REST endpoint — a piece of plumbing with no prior art
anywhere in this codebase, and one this environment has no running emulator to
confirm against.

Written with the uncertainty made explicit rather than buried: a
`VERIFICATION NOTE` on `signInSecondModerator` states plainly that the request
shape is unconfirmed, and that if it silently fails, the test would produce a
false pass — proving only that the second call is broken in some way that
happens to also throw a permission error, not that the actual race is handled.
That distinction matters and is easy to lose in a "test added, ship it" summary.

### The mistake, found by the harness rather than review

Wrote two static checks to guard the fix, then — following this session's own
established practice — tried to prove them with a mutation before trusting them.
The mutation missed. `'db.runTransaction' in resolve_report_src` stayed true
after mutating `resolveReport`'s own transaction call, because the same file
also exports `dedupeReport`, which has its own unrelated `db.runTransaction`.
Removing one occurrence of a substring left the other satisfying the check.

This is the identical "a mention is not a declaration" flaw already found and
fixed twice this session, for `MAX_ORDER_MINOR` and for
`PHASE_1_ALLOWED_PAYMENT_METHODS` — written a third time, by the same author,
inside the very check meant to prevent a different instance of unguarded
concurrent access. Fixed by slicing the source between `resolveReport`'s and
`dedupeReport`'s export boundaries and scoping the check to the function body
that actually matters, the same technique already used for the promo-code rules
check earlier in the session.

Three instances of one mistake in one session is a pattern in how I write
string-based checks, not three unrelated slips — a caution worth stating plainly
rather than treating each occurrence as a fresh surprise. The mutation harness
is the reason this one did not ship silently green; a check I trust without
proving it can fail is exactly the failure mode this whole line of tooling
exists to close.

98 static checks, 20 proven mutations, tree restored clean.

## Forty-sixth pass — partial failure between an external call and a Firestore
## write, and a test-infrastructure gap found while trying to cover the fix

Continued the concurrency/reliability lens into infrastructure-level partial
failure: what happens when a Cloud Function calls an external service
successfully and then fails before it can record that fact.

### `createBunnyUploadSlot` could leak a real, billed video forever

The function creates a video object on Bunny, then writes a `pending_uploads`
document claiming it for the calling user. If that Firestore write throws —
quota, a transient outage, anything — after Bunny's `POST` already succeeded,
the function surfaces an error and the person just tries again. That creates a
**second** video and does nothing about the first, which is now real, billed,
and permanently unowned: no `pending_uploads` document points to it, so no
existing cleanup job in this codebase — including the retention sweep built
earlier this session — has any way to find it.

Fixed with a compensating delete: if the ownership write fails, the function
now attempts to delete the just-created Bunny video before surfacing the error,
so a failed publish attempt does not silently leave debris. If the delete
itself also fails — rare, but not provably impossible, since it would mean
Bunny and Firestore degrading at the same moment — the failure is logged with
both error messages and the video id, rather than swallowed. A function that
swallowed both failures would turn a rare, diagnosable leak into an invisible
one; logging it is what makes "check the Bunny dashboard occasionally" an
actual remedy rather than a hope.

**Flagged rather than assumed**: the compensating `DELETE` call follows Bunny's
documented REST convention and this file's own established request shape (the
same `AccessKey` header and `/videos/{guid}` path `bunnyVideoStatus` already
reads with `GET`), but has not been executed against a live Bunny account in
this environment. If the verb or path is wrong, the practical effect is that
cleanup silently does not happen while looking like it does — which is worse
than the orphan alone, because it removes the incentive to check. A
`VERIFICATION NOTE` says this explicitly at the point someone would rely on it.

The other two Firestore-write cases found by the same search — `onPhoneLinked`
and `liftSuspension` — were already correctly sequenced last pass, and
`processAccountDeletion`'s deletion ordering (profile before Auth record, with
"already gone" treated as success) was already sound on inspection. Three of
four candidates needed nothing; this was the one that did.

### Trying to test the fix surfaced a pre-existing gap: `FakeBunny` is never
### actually in the loop

`integration_test/helpers/fake_bunny.dart` exists specifically so Bunny is not
hit on every CI run, and its own doc comment says so. But `requestUploadSlot`
in the test seed calls the REAL `createBunnyUploadSlot` callable through
`FirebaseFunctions.instance` — there is no dependency-injection seam or local
HTTP substitute that would route the function's own `fetch()` calls to the
fake instead of `video.bunnycdn.com`. Confirmed by an exhaustive search for any
fetch-interception mechanism (`nock`, a mock server, an emulator hook); none
exists anywhere in this codebase.

The practical consequence: `publish_flow_test.dart`'s test for a rejected
61-second duration passes for the right reason by CHANCE, because duration
validation throws before the function reaches its Bunny call — that code path
never touches the network regardless of whether the fake is wired up. But
`'exactly 60 seconds is allowed'` calls the callable with a valid duration,
which reaches the real `fetch()`. With no `BUNNY_API_KEY`/`BUNNY_LIBRARY_ID`
configured in a fresh emulator checkout — and none should be committed — that
call would fail, and the test's `expect(slot, isNotNull)` would fail with it,
for a reason entirely unrelated to the logic the test is meant to verify. The
one assertion made against the fake itself (`bunny.videoCount`) is checked on
the rejected-duration test specifically, the one case where it is trivially
true regardless of what the real function did, because the fake was never
touched.

**This is not fixed in this pass.** Closing it properly means deciding how
`createBunnyUploadSlot` should be made testable — an injectable base URL for
Bunny requests, a local stand-in server the emulator's function process talks
to, or something else — which is a design decision about the function's
testability generally, not a natural side-effect of the orphan-cleanup fix that
led here. Recorded precisely so it is not lost: **the upload-slot tests in
`publish_flow_test.dart` beyond the immediate-rejection case cannot be trusted
to prove what they appear to prove until this seam exists.**

## Forty-seventh pass — local state a server-side cascade structurally cannot
## reach

Shifted the lens again: not server races, not infrastructure partial-failure,
but state that lives only on the device and what happens to it when the
account it belongs to is deleted.

### `SavedLocationStore`'s own doc comment made a claim worth checking

It says plainly: cleared "from account deletion and sign-out." Checking that
specific, falsifiable claim rather than trusting the comment found that only
half of it was true. `AuthBloc._onSignOut` calls `.clear()` correctly.
`AuthRepositoryImpl.deleteAccount()` — a completely separate code path — did
not, and nothing else in the codebase called it either.

### Why this could not have been caught by auditing the deletion cascade

Two passes ago, the equivalent gap (the delivery pin on an *order* surviving
deletion) was closed by finding a field the server-side `accountDeletion.ts`
cascade had drifted behind and adding it there. This is a different shape of
the same class of bug, not the same bug: `SavedLocationStore` is deliberately
never written to Firestore at all — its own doc comment gives the reason, that
a home location is the most sensitive thing this app touches and syncing it
would put it in a document that survives the device and has to be reasoned
about in the deletion cascade. That design choice is sound. Its consequence is
that **no Cloud Function can ever reach this data**, including the one that
processes account deletion — however thorough that cascade is audited, it was
never capable of clearing this, because it was never capable of reaching it.
Clearing it is structurally a client-side responsibility, full stop, and the
client-side deletion request was the one place that responsibility had not
been picked up.

On a shared or family device — common in this market, and already a design
consideration elsewhere in this codebase, per `SavedLocationStore.clear()`'s own
sign-out comment about "the next person's map opens centred on the last
person's home" — this meant a deleted account's home address could persist on
the device indefinitely, discoverable by whoever used it next, with no cleanup
job anywhere capable of ever finding or removing it after the fact.

### The fix follows the exact pattern already proven correct at sign-out

`deleteAccount()` now clears the saved location before writing the
`deletion_requests` document that triggers the server-side cascade — ordered
deliberately, the same reasoning `_onSignOut` already applies to unregistering
the push token before signing out: clear the thing only the client can reach
while the client is still in a position to do it, before handing off to a
process that cannot.

`CartStore` was deliberately left alone. It already has its own 14-day
self-expiry, stores no personal information at all (confirmed two sessions ago:
ids and quantities, never even prices), and a cart is arguably an intention
that outliving one identity on a shared device is a defensible default rather
than an obvious bug — unlike a specific street address, which is unambiguously
personal regardless of context. Scoped to the actual finding rather than
expanded into an unrelated judgment call about cart semantics.

### Two things caught before trusting the fix, following this session's own
### established discipline rather than skipping it because the fix looked small

**A circular import**, confirmed to already exist in exactly this shape
elsewhere (`injector.dart` ↔ `auth_bloc.dart`) before concluding it was safe
here too, rather than assuming Dart tolerates it in general. The actual
constraint that matters is runtime initialization order, not the static import
graph — `AuthRepositoryImpl` is a lazy singleton, so it cannot be constructed
before `configureDependencies()` has already registered `SavedLocationStore`.

**A check that needed self-testing against three shapes, not one.** The static
guard added for this fix was tested against the original unfixed code, the
actual correct fix, and — because presence alone would not have caught it — a
reordered version where `clear()` runs *after* the server write instead of
before. All three produced the correct pass/fail result before the check was
trusted or registered as the 22nd proven mutation.

100 static checks, 22 proven mutations, tree restored clean.

## Forty-eighth pass — auditing my own claims, and a CI step that did nothing

Instead of hunting a new bug, checked whether the "what remains" list I have
been repeating for many passes was still true. One item was stale, and
verifying the rest surfaced a real CI defect.

### The remaining-work list was partly wrong

"13 integration test bodies remain unwritten" was false and had been for a
while: 27 integration tests exist across three files, fully written, zero TODOs.
Repeating a stale status is its own kind of inaccuracy — it understates progress
and, worse, would have sent someone looking for work that was already done.

The other claims held up on inspection: no golden reference images
(`find test -name "*.png"` empty), nothing ever compiled (no `.dart_tool`), and
`assets/fonts/` absent.

### CI ran the wrong codegen step, twice, and omitted the required one

Checking the "never compiled" claim surfaced a contradiction: the README states
plainly there is no `build_runner` step, while CI ran
`dart run build_runner build --delete-conflicting-outputs` in two separate jobs.

The README is right. This project has **no code generation at all**: DI is
registered by hand (injector.dart explains why — hand-written wiring runs on a
fresh clone before any codegen, and is the file a new engineer reads to learn
what depends on what), and there is not one `@freezed`, `@JsonSerializable`,
`Init` or `part` directive anywhere in `lib/`. The ``
annotations are deliberately decorative, kept so switching to generated wiring
stays a one-command change.

So the `build_runner` steps produced nothing — pure build time, plus the false
impression that codegen was part of this workflow.

**The more consequential half:** `flutter gen-l10n` — which the README says is
mandatory, and without which every label in the app renders blank — was **not in
CI at all**. So `flutter analyze` and every widget test in CI ran against the
checked-in placeholder stub that returns empty strings, passing while proving
less than they appeared to. Both `build_runner` steps are now `gen-l10n`, and
all three jobs that fetch packages generate localizations.

Guarded by two new checks, both registered as mutations and confirmed to fail
when broken. The `build_runner` check reads the comment-stripped CI text
specifically because the comment explaining the decision says "build_runner"
itself — the same self-matching trap already hit twice this session.

### The harness could corrupt the repository when killed

Extending it exposed a real defect in the harness itself. Mutations are undone
in a `finally`, which handles exceptions but **not a hard kill** — and at 24
mutations × ~13s per checker run, the full suite takes about six minutes and
exceeds a typical command timeout. It was killed twice while being extended,
once leaving a deliberately-broken TypeScript import in `triggers.ts` and once
leaving five files mutated. Both were noticed only because a later check failed
for an unrelated-looking reason, which is exactly the kind of confusing failure
that wastes an afternoon.

Two fixes:

- **Crash recovery.** Backups now go to a predictable path rather than a random
  temp dir, and any left from a killed run are restored on startup before
  anything else happens. Verified working: it recovered `triggers.ts`
  automatically on the next invocation. The `/`→`__` path encoding was checked
  against all 17 mutation target paths to confirm none contains a literal
  double underscore that would decode to the wrong file — restoring to the
  wrong path being worse than not restoring at all.
- **Selective execution.** `--list` shows labels without running anything, and
  substring filters run only relevant mutations (`verify_checks.py payment`).
  CI still runs the full set, where six minutes is affordable. A harness nobody
  can run locally is a harness that stops being run, which defeats its purpose
  more thoroughly than any individual weak check.

102 static checks, 24 registered mutations, tree verified clean at 102/102.

## Forty-ninth pass — ruling out compile failures without a compiler

Applied last pass's scepticism to the largest remaining claim: that first compile
is genuinely blocked. Verified rather than assumed — no `dart` or `flutter` on
PATH, no SDK in any standard location, and `npm install` fails with a 403 against
the registry. The claim holds; there is no way to run a real build here.

But Node 22 and Java 21 ARE present, and `functions/tsconfig.json` sets
`strict: true`, `noUnusedLocals: true` and `noImplicitReturns: true` — three
settings that reject code no static check in this repository examines. Those are
real build-breakers, and two of them can be approximated well enough to be worth
the attempt.

### `noUnusedLocals`: zero real problems, seven false positives from my own tool

The first sweep reported 39 hits — almost all of them `export const x =
onCall(...)` handlers, flagged because the detector counted occurrences within a
single file and an exported handler is legitimately referenced nowhere else in
its own. `noUnusedLocals` does not apply to exports at all. Corrected to examine
only genuinely local declarations, which left seven.

All seven were also false positives, and the cause is worth recording: the
shared `strip_ts()` helper blanks template literals wholesale, so a variable used
only as `${host}` inside one appears unused. Verified against the raw source and
then confirmed by reading two of them directly — `host` is used in
`` `https://${host}${path}...` ``, `commenterName` in
`` `${commenterName} commented` ``. Every one was real, working code that
"fixing" would have broken.

So: the codebase is clean under `noUnusedLocals`. One compile-failure category
ruled out without a compiler — an unglamorous result, but a real one, and the
alternative was discovering it at first build.

The tooling lesson is the more durable outcome. `strip_ts()` now carries an
explicit warning that it is **unsuitable for counting identifier usages**, since
I have used it for several checks and would otherwise have reached for it again
for exactly this kind of sweep. Structural questions like delimiter balance are
what it is for; usage counts need the raw source.

### `strict` null-safety on Firestore triggers: clean

`event.data` is possibly-undefined in v2 trigger handlers, and accessing
`event.data.foo` without a guard is among the most common strict-mode failures
in this exact codebase shape. Every use is guarded with `?.` or an explicit
existence check. No hits.

### What this pass did not establish

Approximating three compiler settings is not compiling. Type errors, generic
mismatches, and Dart-side analysis remain entirely unverified and still require
a real toolchain. This narrowed the unknown; it did not remove it.

102 static checks, 24 registered mutations, tree clean.

## Fiftieth pass — the third strict setting, and a fragile exhaustiveness
## dependency worth pinning

Continued ruling out compile-failure categories without a compiler.
`noImplicitReturns` was the last of the three strict settings unchecked.

### One candidate, and it was a real question rather than a false positive

Unlike the previous two sweeps — which produced only false positives from my own
tooling — this one surfaced something that genuinely needed investigating:
`deepLinkFor()` returns `string | null` and contains a `switch` with **no
`default` branch**. Whether that compiles depends entirely on exhaustiveness.
TypeScript's control-flow analysis knows the end of a switch is unreachable if
every member of a union is covered, and `noImplicitReturns` is satisfied. Miss
one member and it is a hard build failure.

Compared the two sets programmatically rather than by eye, since a ten-member
union is exactly where manual comparison slips: all ten covered, none extra.
**Exhaustive, so it compiles.** Third compile-failure category ruled out.

### But the exhaustiveness is load-bearing and fragile

`NotificationType` is now depended on in three places, and a mismatch in any of
them fails the build rather than misbehaving at runtime:

1. the union type itself
2. `CHANNEL_OF: Record<NotificationType, Channel>` — TypeScript requires every
   key, so a missing or extra one will not compile
3. `deepLinkFor`'s switch, which relies **only** on exhaustiveness

The third is the subtle one. Adding an eleventh notification type — a completely
ordinary future change — breaks the build in `deepLinkFor` with an error pointing
at that function rather than at the type that actually changed, which is a
confusing place to begin debugging.

Both dependents are now pinned by checks that name the real cause up front, and
both were proven by adding a `"price_drop"` member and confirming they light up.
Registered as the 25th mutation.

Also confirmed `CHANNEL_OF` is currently complete in both directions — no
missing keys, no extras.

### A note on the tooling paying for itself

Verifying the new mutation took about twenty seconds using the substring filter
added last pass, rather than the six-minute full run that had been timing out.
That filter existed specifically so mutations stay verifiable as they
accumulate, and this is the first pass where it was the difference between
checking and not checking.

104 static checks, 25 registered mutations, tree clean.

## Fifty-first pass — the Dart side, and where static approximation runs out

Moved from TypeScript to the much larger unverified surface: Dart. CI runs
`flutter analyze --fatal-infos` against `very_good_analysis`, so even
informational lints fail the build. Two enabled rules looked mechanically
checkable.

### `always_use_package_imports`: no violation, and I nearly "fixed" it wrongly

Three widget tests import `'../helpers/pump_app.dart'` relatively, and my first
read called that a build failure. It is not, for a reason that took actually
checking to establish: **`package:wave/` maps only to `lib/`**, so there is no
legal `package:` URI for a file under `test/helpers/` at all — package URIs
cannot traverse outside `lib/`. The lint cannot be satisfied by rewriting these,
because the target is not in the package. Had I "fixed" them, I would have
produced three imports that cannot resolve.

Confirmed no test anywhere imports a helper via `package:`, which is consistent
with there being no such path.

### `prefer_const_constructors`: 19 candidates, 19 false positives

The sweep flagged 19. Sampling three before changing anything found three
*separate* flaws in a one-line regex:

- **Enum const-constructor arguments** (`write_throttle.dart`) are already a
  const context.
- **Library prefixes** — `pw.SizedBox` is the PDF library's class, not
  Flutter's; the pattern matched the bare name and ignored `pw.`.
- **Const propagation** — `return const Column(children: [...])` makes every
  child const already. Adding the keyword would trip a *different* lint,
  `unnecessary_const`.

Correcting for all three left one candidate, which was also inside a
`const SliverToBoxAdapter(...)`. So: **all 19 were false positives, and the
corrected detector still produced one.**

That is the finding worth keeping. `prefer_const_constructors` requires real
const-context analysis — whether an enclosing expression is const, whether a
prefix resolves to a different class, whether constness propagates into a
collection literal. That is what an analyzer does, and it is not approximable
with pattern matching. I stopped rather than iterate toward a detector that
would be wrong in a new way.

### The pattern across the last four sweeps

`noUnusedLocals` (39 then 7 false positives), `noImplicitReturns` (1 real
question, resolved as compliant), `always_use_package_imports` (3 apparent
violations, 0 real), `prefer_const_constructors` (19 apparent, 0 real). Every
one of my initial readings looked like a real bug and was my own
misunderstanding — usually of the tool I had just written.

Two conclusions. First, verifying a sample before acting has now prevented four
rounds of damaging "fixes"; it is not optional diligence. Second, the
cheap-to-approximate compile categories are exhausted. What remains — type
errors, generic mismatches, const analysis, the whole Dart surface — genuinely
needs a toolchain, and further static invention would produce false confidence
rather than information.

104 static checks, 25 registered mutations, tree clean. No code changed this
pass, which is the correct outcome when every candidate is a false positive.

## Fifty-second pass — reading the deliverable as its recipient

Last pass concluded that inventing more static checks would manufacture
confidence rather than information. So instead of writing another detector, I
extracted the shipped archive into a clean directory and read it as someone
receiving it for the first time.

That immediately surfaced a file I had never once looked at in fifty-one passes.

### `build.yaml` silently contradicted a documented decision

It configures `injectable_generator` and `json_serializable`. Two passes ago I
removed `build_runner` from CI on the grounds — verified then and re-verified
from the fresh extraction now — that `lib/` contains zero `Init`,
zero `@JsonSerializable`, zero `@freezed` and zero `part` directives. Both
builders have nothing to generate.

The file is unmentioned in the README, which states plainly "there is no
`build_runner` step." So a recipient finds a codegen config with no explanation
that flatly contradicts the setup instructions, and the reasonable inference is
that CI is missing a step. That is precisely the mistake I had just finished
removing — reintroduced by a file I had never read.

Deleting it would have been the wrong fix. Every repository and BLoC keeps its
`` annotation on purpose so switching to generated wiring stays cheap,
and `field_rename: snake` is load-bearing for any future migration: every
Firestore document here uses snake_case while Dart uses camelCase, and generated
serialization without that option would write camelCase keys alongside the
snake_case ones already in the database — a data-corruption bug that presents as
missing fields rather than as a config mistake.

So the file now explains itself: dormant, why it is kept, why that specific
option matters, and an explicit instruction not to add a CI step on the strength
of its existence. Guarded by a check that requires the explanation rather than
forbidding the file, and proven by stripping the header back to the bare config
and confirming it fails.

### What else the fresh-eyes read confirmed

Three things I had asserted repeatedly but never verified from a clean
extraction:

- **`gen-l10n`'s inputs are all present and consistent** — `l10n.yaml` names
  `app_en.arb` as the template, and all three ARB files ship.
- **The `.gitignore` negation is correct.** `lib/l10n/generated/*` is ignored
  with `!lib/l10n/generated/app_localizations.dart` negated back in, so the
  checked-in placeholder survives a recipient's first `git` operation rather
  than being swept away by the rule that ignores its neighbours.
- **The placeholder stub genuinely covers all 429 ARB keys** and declares all
  three locales, so a fresh clone analyses before `gen-l10n` has run — which is
  the entire reason the stub is committed, and had never actually been checked
  against the shipped artifact rather than the working copy.

### The lesson

Fifty-one passes of auditing the code missed a top-level config file, because
every pass started from a question about behaviour and none started from "what
does the recipient see." Both readings are necessary; they find different things.

105 static checks, 25 registered mutations, tree clean.
