import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/config/remote_config_keys.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/services/remote_config_service.dart';
import 'package:wave/core/utils/rate_limiter.dart';
import 'package:wave/core/utils/result.dart';
import 'package:wave/features/auth/domain/entities/wave_user.dart';
import 'package:wave/features/auth/domain/repositories/auth_repository.dart';
import 'package:wave/features/location/data/saved_location_store.dart';


class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._auth,
    this._db,
    this._functions,
    this._analytics,
    this._config,
  );

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final AnalyticsService _analytics;
  final RemoteConfigService _config;

  /// Consent captured on the sign-in screen, held until there is a profile
  /// document to write it to.
  ({bool acceptedTerms, bool confirmedAge, String termsVersion})? _consent;

  @override
  void captureConsent({
    required bool acceptedTerms,
    required bool confirmedAge,
    required String termsVersion,
  }) {
    _consent = (
      acceptedTerms: acceptedTerms,
      confirmedAge: confirmedAge,
      termsVersion: termsVersion,
    );
  }

  /// Client-side OTP throttle (§1). The real cap is enforced by App Check plus
  /// a Cloud Function counter — this just prevents an accidental burst and
  /// gives immediate feedback. Unprotected phone auth is a well-known way to
  /// accidentally fund an SMS-pumping bot farm, so both layers ship together.
  /// Per-NUMBER throttle, keyed by the phone number below.
  ///
  /// Built from Remote Config so the cap can be tightened DURING an abuse wave
  /// rather than in the next release. That is the point of the knob: an
  /// SMS-pumping attack is discovered while it is happening, and a fix that
  /// needs an App Store review is not a fix.
  ///
  /// Note what this can and cannot do. Keyed by number, it stops one number
  /// being hammered from this device. It cannot see requests from OTHER
  /// devices, so the per-device cap — the one that stops a farm rotating
  /// through numbers — has to be enforced server-side alongside App Check.
  /// `otpMaxPerDevicePerDay` exists for that enforcement, not for this class.
  late final _otpLimiter = RateLimiter(
    maxEvents: _otpCapPerNumber,
    window: const Duration(minutes: 15),
  );

  int get _otpCapPerNumber {
    final v = _config.getInt(RemoteConfigKeys.otpMaxPerNumberPerDay);
    // A daily cap spread across the 15-minute window, floored at 1 so a
    // misconfigured zero cannot lock everyone out of signing up entirely.
    return v == 0 ? 3 : (v ~/ 2).clamp(1, 20);
  }

  @override
  Stream<WaveUser?> get authState =>
      _auth.authStateChanges().asyncMap(_toWaveUser);

  @override
  WaveUser? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    return WaveUser(
      uid: u.uid,
      isGuest: u.isAnonymous,
      // Optimistic until the profile doc loads; the gate re-checks server-side.
      phoneVerified: u.phoneNumber != null,
      displayName: u.displayName,
      email: u.email,
      phoneNumber: u.phoneNumber,
      photoUrl: u.photoURL,
    );
  }

  Future<WaveUser?> _toWaveUser(fb.User? u) async {
    if (u == null) return null;
    final doc = await _db.collection('users').doc(u.uid).get();
    final data = doc.data() ?? const <String, dynamic>{};
    return WaveUser(
      uid: u.uid,
      isGuest: u.isAnonymous,
      phoneVerified: data['phone_verified'] as bool? ?? false,
      displayName: u.displayName ?? data['display_name'] as String?,
      email: u.email,
      phoneNumber: u.phoneNumber,
      photoUrl: u.photoURL,
      acceptedTermsVersion: data['accepted_terms_version'] as String?,
      ageConfirmed: data['age_confirmed'] as bool? ?? false,
    );
  }

  @override
  Future<Result<WaveUser>> signInWithGoogle() async {
    try {
      final google = await GoogleSignIn().signIn();
      if (google == null) {
        return const Err(
          AuthFailure(
            'Sign-in cancelled',
            reason: FailureReason.signInCancelled,
          ),
        );
      }
      final gAuth = await google.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      // Awaited, not returned directly. `_completeSignIn` can throw
      // fb.FirebaseAuthException just as much as the calls above it — a
      // duplicate-credential race during `linkWithCredential`, for instance —
      // and returning its Future unawaited let that exception escape past the
      // `catch` immediately below rather than through it. The failure still
      // surfaced, just as an unhandled async error instead of an AuthFailure,
      // which is a worse shape for a caller to have to handle.
      return await _completeSignIn(credential);
    } on fb.FirebaseAuthException catch (e) {
      return Err(
        AuthFailure(
          e.message ?? 'Sign-in failed',
          code: e.code,
          reason: FailureReason.signInFailed,
        ),
      );
    }
  }

  @override
  Future<Result<WaveUser>> signInWithApple() async {
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final credential = fb.OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      // See the identical note in signInWithGoogle above: unawaited, an
      // exception from _completeSignIn bypassed the catch below it entirely.
      return await _completeSignIn(credential);
    } on fb.FirebaseAuthException catch (e) {
      return Err(AuthFailure(e.message ?? 'Sign-in failed', code: e.code));
    }
  }

  /// Upgrades an anonymous session in place where possible, so a guest who
  /// filled a cart keeps it. Falls back to a plain sign-in if the credential
  /// already belongs to another account.
  Future<Result<WaveUser>> _completeSignIn(fb.AuthCredential credential) async {
    final existing = _auth.currentUser;
    fb.UserCredential result;

    if (existing != null && existing.isAnonymous) {
      try {
        result = await existing.linkWithCredential(credential);
        // The upgrade succeeded in place, so the cart and favourites survived.
        // Worth measuring separately from a fresh sign-up: it is the guest
        // funnel converting, which is a different question.
        await _analytics.log(AnalyticsEvents.guestUpgraded);
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          // The user already has a real account. Sign into that instead; the
          // guest cart is merged separately by the cart repository.
          result = await _auth.signInWithCredential(credential);
        } else {
          rethrow;
        }
      }
    } else {
      result = await _auth.signInWithCredential(credential);
    }

    final user = await _toWaveUser(result.user);
    if (user == null) {
      return const Err(
        AuthFailure('Sign-in failed', reason: FailureReason.signInFailed),
      );
    }
    await _ensureProfile(user);
    return Success(user);
  }

  Future<void> _ensureProfile(WaveUser user) async {
    final ref = _db.collection('users').doc(user.uid);
    final consent = _consent;

    await ref.set(
      {
        'display_name': user.displayName,
        'photo_url': user.photoUrl,
        'updated_at': FieldValue.serverTimestamp(),

        // Consent is written on first sign-in and never overwritten afterwards:
        // a later session must not silently re-stamp an acceptance the user gave
        // against an older version of the terms. Re-acceptance goes through the
        // versioned gate in the legal feature instead.
        if (consent != null && consent.acceptedTerms) ...{
          'accepted_terms_version': consent.termsVersion,
          'accepted_terms_at': FieldValue.serverTimestamp(),
          'accepted_legal': {'terms': consent.termsVersion},
        },
        if (consent != null && consent.confirmedAge) ...{
          'age_confirmed': true,
          'age_confirmed_at': FieldValue.serverTimestamp(),
        },

        // Never write phone_verified from the client — only the Cloud Function
        // does, and Security Rules reject it from anywhere else.
        'created_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // Consumed once. Holding it would re-stamp on every subsequent sign-in.
    _consent = null;
  }

  @override
  Future<Result<WaveUser>> continueAsGuest() async {
    try {
      final result = await _auth.signInAnonymously();
      final user = await _toWaveUser(result.user);
      return user == null
          ? const Err(
              AuthFailure(
                'Could not start a guest session',
                reason: FailureReason.guestSessionFailed,
              ),
            )
          : Success(user);
    } on fb.FirebaseAuthException catch (e) {
      return Err(
        AuthFailure(
          e.message ?? 'Guest session failed',
          code: e.code,
          reason: FailureReason.guestSessionFailed,
        ),
      );
    }
  }

  @override
  Future<Result<String>> sendOtp(String phoneNumber) async {
    final wait = _otpLimiter.check(phoneNumber);
    if (wait != null) {
      return Err(
        RateLimitedFailure(
          'Too many codes requested',
          retryAfter: wait,
          reason: FailureReason.codeSendThrottled,
        ),
      );
    }

    // Server-side check FIRST. Asking afterwards would mean the SMS has
    // already been sent and paid for.
    try {
      await _functions.httpsCallable('checkOtpAllowance').call<void>({
        'phoneNumber': phoneNumber,
      });
    } on FirebaseFunctionsException catch (e) {
      return Err(
        e.code == 'resource-exhausted'
            ? RateLimitedFailure(
                e.message ?? 'Too many codes requested',
                reason: FailureReason.codeSendThrottled,
              )
            : AuthFailure(
                e.message ?? 'Could not send a code',
                code: e.code,
                reason: FailureReason.codeSendFailed,
              ),
      );
    }

    final completer = Completer<Result<String>>();
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (_) {
          // Android auto-retrieval. The UI still shows the code field; this
          // just fills it in.
        },
        verificationFailed: (e) {
          if (!completer.isCompleted) {
            completer.complete(
              Err(
                AuthFailure(
                  e.message ?? 'Could not send code',
                  code: e.code,
                  reason: FailureReason.codeSendFailed,
                ),
              ),
            );
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) {
            completer.complete(Success(verificationId));
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
      // Awaited rather than `return completer.future;`. The unawaited form put
      // the completer's Future outside this try block's effective coverage: if
      // completing it later somehow threw (or, more realistically, a linter
      // and a future maintainer both reasonably assume a try/catch here means
      // every failure from this method is caught), the `catch` below it would
      // never run. `await` puts the resolution — success or failure — back
      // inside the block the catch actually guards.
      return await completer.future;
    } on fb.FirebaseAuthException catch (e) {
      return Err(
        AuthFailure(
          e.message ?? 'Could not send code',
          code: e.code,
          reason: FailureReason.codeSendFailed,
        ),
      );
    }
  }

  @override
  Future<Result<WaveUser>> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final result = await _completeSignIn(credential);

    // Signing in WITH a phone verifies it just as much as linking one does.
    // Without this, anyone who chose phone as their sign-in method would still
    // be stopped at the checkout gate and asked to verify the number they had
    // just used to sign in.
    if (result is Err<WaveUser>) return result;

    final failure = await _confirmPhoneVerified();
    if (failure != null) return Err(failure);

    final refreshed = await _toWaveUser(_auth.currentUser);
    return refreshed == null ? result : Success(refreshed);
  }

  /// Asks the backend to confirm the phone on the auth record and set
  /// `phone_verified`.
  ///
  /// Returns null on success, or the failure to surface. The function re-reads
  /// the auth record with the Admin SDK rather than trusting anything in the
  /// request, so a client cannot talk its way past the gate.
  Future<Failure?> _confirmPhoneVerified() async {
    try {
      await _functions.httpsCallable('onPhoneLinked').call<void>();
      return null;
    } on FirebaseFunctionsException catch (e) {
      return AuthFailure(
        e.message ?? 'Could not verify your number',
        code: e.code,
        // The provider's code picks the reason; the reason picks the words, in
        // whatever language the person is reading. Mapping straight to an
        // English sentence here is what made these permanently untranslatable.
        reason: switch (e.code) {
          'already-exists' => FailureReason.phoneOnAnotherAccount,
          'failed-precondition' => FailureReason.phoneLinkFailed,
          _ => FailureReason.verificationFailed,
        },
      );
    }
  }

  @override
  Future<Result<WaveUser>> linkPhoneToCurrentUser({
    required String verificationId,
    required String smsCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const Err(
        AuthFailure('Not signed in', reason: FailureReason.notSignedIn),
      );
    }

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await user.linkWithCredential(credential);
      await user.reload();

      // `phone_verified` is the flag the checkout gate reads, and Security
      // Rules forbid the client from writing it — so this call is the ONLY
      // thing that can set it. Without it the gate is permanently closed and
      // nobody can ever place an order.
      //
      // It is a callable, not a background trigger. `linkWithCredential`
      // fires no Firestore write and therefore nothing to trigger on, which
      // is exactly why it has to be invoked explicitly here.
      final verified = await _confirmPhoneVerified();
      if (verified != null) return Err(verified);

      final refreshed = await _toWaveUser(_auth.currentUser);
      return refreshed == null
          ? const Err(
              AuthFailure(
                'Verification failed',
                reason: FailureReason.verificationFailed,
              ),
            )
          : Success(refreshed);
    } on fb.FirebaseAuthException catch (e) {
      return Err(
        AuthFailure(
          e.message ?? 'Verification failed',
          code: e.code,
          reason: switch (e.code) {
            'invalid-verification-code' => FailureReason.codeIncorrect,
            'credential-already-in-use' => FailureReason.phoneOnAnotherAccount,
            'session-expired' => FailureReason.codeExpired,
            _ => FailureReason.verificationFailed,
          },
        ),
      );
    }
  }

  @override
  Future<Result<void>> sendRecoveryEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Success(null);
    } on fb.FirebaseAuthException catch (e) {
      // 'user-not-found' is swallowed on purpose: reporting it would let anyone
      // check whether an address has an account here, which is exactly the
      // enumeration this endpoint would otherwise hand out for free.
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        return const Success(null);
      }
      return Err(
        AuthFailure(
          e.message ?? 'Could not send the email',
          code: e.code,
          reason: FailureReason.recoveryEmailFailed,
        ),
      );
    }
  }

  @override
  Future<Result<void>> startPhoneRecovery(String phoneNumber) async {
    // Recovery by phone IS the OTP flow: proving control of the number on the
    // account is proof enough to get back into it. Routing through sendOtp
    // keeps the rate limiting and App Check checks in one place rather than
    // creating a second, less guarded way to trigger an SMS.
    final result = await sendOtp(phoneNumber);
    return result.fold(Err.new, (_) => const Success(null));
  }

  @override
  Future<Result<void>> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    // Right to be forgotten (§7). The client only requests it; a Cloud Function
    // does the cascading delete across orders, reels, reviews and storage.
    final user = _auth.currentUser;
    if (user == null) {
      return const Err(
        AuthFailure('Not signed in', reason: FailureReason.notSignedIn),
      );
    }

    // The saved delivery pin is cleared HERE, client-side, because it can be
    // nowhere else. It lives in SharedPreferences specifically so it never
    // reaches a Firestore document — see the note on SavedLocationStore — and
    // that means no server-side Cloud Function, including the one that
    // processes this very deletion request, can ever reach it. If this call
    // is skipped, the pin survives the account it belonged to indefinitely: on
    // a shared or family device, the next person's map opens centred on a
    // deleted stranger's home, and there is no cleanup job anywhere that could
    // ever find it to fix it later — this is the only line in the codebase
    // capable of clearing it.
    //
    // Sign-out already does this (see AuthBloc._onSignOut). Account deletion
    // did not, despite deletion being the more permanent and more sensitive of
    // the two — the same class of gap already found twice this session for
    // fields that drifted behind the server-side deletion cascade, except this
    // one could never have been caught by auditing that cascade at all, since
    // the data it is missing was never something a server-side function could
    // reach in the first place.
    await getIt<SavedLocationStore>().clear();

    await _db.collection('deletion_requests').doc(user.uid).set({
      'requested_at': FieldValue.serverTimestamp(),
      'uid': user.uid,
    });
    return const Success(null);
  }
}
