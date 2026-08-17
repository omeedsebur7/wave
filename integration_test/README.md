# Integration tests

These run against the **Firebase emulator suite**, never production.

```bash
# Terminal 1
firebase emulators:start --only auth,firestore,functions,storage

# Terminal 2
flutter test integration_test \
  --dart-define=USE_EMULATOR=true

# On an Android emulator the host is not localhost:
flutter test integration_test \
  --dart-define=USE_EMULATOR=true \
  --dart-define=EMULATOR_HOST=10.0.2.2
```

`USE_EMULATOR` is a compile-time flag, and `EmulatorConfig.connect()` asserts it
is never set in release mode. There is deliberately no runtime switch — a test
suite that *can* point at production is one that eventually will.

## Why the seeder uses the client SDK

`TestSeed` writes with the normal client SDK, so every seeded document passes
through the same Security Rules the app does. A seeder using the Admin SDK would
bypass them, and tests would pass against data the app itself could never have
created — which is the failure mode where your rules are broken and every test
is green.

`seedDeliveredOrder` is the interesting case. The client cannot write
`status: delivered` directly; the rules only allow the seller's step-by-step
transitions. So it walks the order through the real state machine, which
exercises those transitions as a side effect.

## Two fields the client genuinely cannot set

`phone_verified` and `trust_tier` are function-only by design — a client that
could set `phone_verified` would bypass the entire checkout gate. Tests needing
a verified buyer must either call the `onPhoneLinked` callable against the
emulator, or write via the emulator's REST endpoint, which ignores rules:

```bash
curl -X PATCH \
  "http://localhost:8080/v1/projects/$PROJECT/databases/(default)/documents/users/$UID?updateMask.fieldPaths=phone_verified" \
  -H 'Authorization: Bearer owner' \
  -d '{"fields":{"phone_verified":{"booleanValue":true}}}'
```

That escape hatch exists only because the emulator accepts `Bearer owner`.
Nothing equivalent exists in production, which is the point.

## Testing a race between two people

`TestSeed.signInReadyBuyer()` signs in on `FirebaseAuth.instance` — the single,
shared auth session every other helper method assumes. Calling it twice does not
give you two buyers; it replaces the first buyer with the second, because a
client SDK's auth state is exactly the thing it assumes is singular.

That is fine for almost every test, and wrong for exactly one kind: proving what
happens when two *different* people act at the same moment, such as two buyers
racing for the last unit of something in stock. `TestSeed.signInSecondBuyer()`
exists for that case. It opens a second, independent `FirebaseApp` — its own
`FirebaseAuth`, `FirebaseFirestore`, `FirebaseFunctions` — wired to the same
emulator suite, so the two identities are as separate as two different phones
would be. Firing both calls through `Future.wait` then exercises Firestore's
real optimistic-concurrency retry, not a mock of one.

Reach for this only when the thing under test is genuinely about two identities
overlapping in time. For anything else it is unnecessary ceremony — most races
worth testing are actually about a single resource under a single transaction,
which `runTransaction`'s automatic retry already handles, and the sequential
double-submit pattern (fire the same idempotency key twice, in order) proves
that without the cost of a second app instance.

See `purchase_flow_test.dart`, group `'Concurrent purchases cannot oversell
stock'`, for the full pattern including cleanup — a second `FirebaseApp` must be
disposed with `.dispose()` at the end of the test, or it leaks into the next
one.
