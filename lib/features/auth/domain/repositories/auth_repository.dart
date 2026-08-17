import 'package:wave/core/utils/result.dart';
import 'package:wave/features/auth/domain/entities/wave_user.dart';

abstract class AuthRepository {
  Stream<WaveUser?> get authState;
  WaveUser? get currentUser;

  /// Records the consent captured on the sign-in screen (§1, §7).
  ///
  /// Taken as an explicit call rather than a side effect of signing in,
  /// because the two happen at different moments: consent is given before the
  /// provider sheet opens, and the account may not exist until after it
  /// closes. Buffered and written once there is a profile to write to.
  void captureConsent({
    required bool acceptedTerms,
    required bool confirmedAge,
    required String termsVersion,
  });

  Future<Result<WaveUser>> signInWithGoogle();

  /// Kept in Phase 1 because Apple's App Store review requires it wherever
  /// Google Sign-In is offered on iOS — not a nice-to-have (§1).
  Future<Result<WaveUser>> signInWithApple();

  /// Guest mode: browse Reels and the Marketplace without an account (§1).
  /// Implemented as Firebase anonymous auth so the session can later be
  /// UPGRADED via linkWithCredential, preserving cart and favourites rather
  /// than throwing them away at sign-up.
  Future<Result<WaveUser>> continueAsGuest();

  Future<Result<String>> sendOtp(String phoneNumber);

  /// [verificationId] comes from [sendOtp]. Returns the (possibly upgraded)
  /// user.
  Future<Result<WaveUser>> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Attaches a verified phone to an EXISTING Google/Apple account without
  /// creating a second user — the checkout gate path (§5.2).
  Future<Result<WaveUser>> linkPhoneToCurrentUser({
    required String verificationId,
    required String smsCode,
  });

  /// Account recovery (§1).
  ///
  /// Phone is the primary path: most accounts here are created with a phone
  /// number, and an OTP to a number already on the account both recovers access
  /// and re-proves the number in one step. The email path exists for
  /// Google/Apple accounts whose phone has since changed.
  Future<Result<void>> sendRecoveryEmail(String email);

  /// Starts phone-based recovery.
  ///
  /// Answers identically for a registered and an unregistered number,
  /// deliberately — a differentiated answer turns this into an oracle for which
  /// numbers have accounts.
  Future<Result<void>> startPhoneRecovery(String phoneNumber);

  Future<Result<void>> signOut();
  Future<Result<void>> deleteAccount();
}
