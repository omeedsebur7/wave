import 'package:wave/core/error/failures.dart';
import 'package:wave/design_system/components/wave_state_view.dart';

/// Decides which error SCREEN a [Failure] gets.
///
/// This does not decide the WORDS. `failureText(context, failure)` already does
/// that, exhaustively, from ~100 FailureReason values — far more specific than
/// any screen-level switch could be. Pass its output to
/// `WaveFailure(..., detail: ...)` so the two systems compose instead of
/// competing:
///
///     final kind = waveFailureKind(f);
///     WaveFailure(
///       kind,
///       detail: failureText(context, f),
///       onRetry: isRetryable(kind) ? retry : null,
///     );
///
/// Reason is checked before type, because reason cuts across the hierarchy: a
/// ServerFailure carrying `networkUnavailable` is an offline screen, not a
/// server-error screen. The type switch below is the fallback, and it is
/// exhaustive over the sealed hierarchy — a new Failure subclass is a compile
/// error here rather than a silent fall-through to "something went wrong".
WaveFailureKind waveFailureKind(Failure failure) {
  final byReason = _kindForReason(failure.reason);
  if (byReason != null) return byReason;

  return switch (failure) {
    NetworkFailure() => WaveFailureKind.noConnection,
    OutOfStockFailure() => WaveFailureKind.outOfStock,
    NotFoundFailure() => WaveFailureKind.notFound,
    RateLimitedFailure() => WaveFailureKind.rateLimited,
    AuthFailure() => WaveFailureKind.sessionExpired,

    // A missing verified phone at checkout is not an error, it is an unmet
    // prerequisite with an obvious next step. Routing it to an error screen is
    // the wrong shape — it should push the verification flow. Mapped
    // conservatively until checkout is migrated and can handle it properly.
    PhoneVerificationRequiredFailure() => WaveFailureKind.serverError,

    // Permission here means Firestore rules said no, not an OS permission
    // prompt. locationDenied is the OS case and arrives via reason instead.
    PermissionFailure() => WaveFailureKind.serverError,

    ServerFailure() => WaveFailureKind.serverError,
  };
}

/// Reasons whose screen is decided by the reason rather than the failure type.
///
/// Returns null when the reason carries no screen-level meaning, which is the
/// common case — most reasons only change the wording, and wording is
/// `failureText`'s job.
WaveFailureKind? _kindForReason(FailureReason reason) => switch (reason) {
      FailureReason.networkUnavailable ||
      FailureReason.uploadNeedsConnection =>
        WaveFailureKind.noConnection,

      FailureReason.outOfStock => WaveFailureKind.outOfStock,

      FailureReason.productNotFound ||
      FailureReason.orderNotFound ||
      FailureReason.reelNotFound ||
      FailureReason.sellerNotFound ||
      FailureReason.documentNotPublished =>
        WaveFailureKind.notFound,

      FailureReason.deliveryLocationRequired => WaveFailureKind.locationDenied,

      FailureReason.codeSendThrottled ||
      FailureReason.promoThrottled ||
      FailureReason.checkoutThrottled ||
      FailureReason.reportThrottled ||
      FailureReason.followThrottled ||
      FailureReason.publishThrottled ||
      FailureReason.messagingTooFast ||
      FailureReason.commentingTooFast =>
        WaveFailureKind.rateLimited,

      FailureReason.notSignedIn ||
      FailureReason.codeExpired =>
        WaveFailureKind.sessionExpired,

      // Everything else: the reason changes the words, not the screen.
      _ => null,
    };

/// Whether offering Retry makes sense.
///
/// A deleted product is still deleted on the second tap. Offering Retry there
/// is the dead end deep links actually hit — someone opens a shared link to a
/// sold listing and gets a button that can never work.
bool isRetryable(WaveFailureKind kind) => switch (kind) {
      WaveFailureKind.noConnection => true,
      WaveFailureKind.serverError => true,
      WaveFailureKind.paymentDeclined => true,
      WaveFailureKind.locationDenied => true,

      // Retryable, but not immediately. The screen should count down from
      // RateLimitedFailure.retryAfter rather than offer a button that fails.
      WaveFailureKind.rateLimited => false,

      WaveFailureKind.notFound => false,
      WaveFailureKind.outOfStock => false,
      WaveFailureKind.sessionExpired => false,
    };

/// The `signInTo*` reasons deliberately have no mapping to error screens.
/// signInToSaveProducts, signInToComment, signInToReview, signInToSell and the
/// rest are prompts, not failures. Blanking a working product page to say "sign
/// in to save products" would be a far worse outcome than the tap doing
/// nothing. They belong in a sign-in sheet or a snackbar.
bool isSignInPrompt(FailureReason reason) => switch (reason) {
      FailureReason.notSignedIn ||
      FailureReason.signInToLikeReels ||
      FailureReason.signInToSaveReels ||
      FailureReason.signInToComment ||
      FailureReason.signInToReview ||
      FailureReason.signInToRate ||
      FailureReason.signInToSell ||
      FailureReason.signInToFollow ||
      FailureReason.signInToReport ||
      FailureReason.signInToMessage ||
      FailureReason.signInToSaveProducts => true,
      _ => false,
    };
