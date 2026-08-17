import 'package:equatable/equatable.dart';

/// Why something failed, in a form the presentation layer can translate.
///
/// This exists because [Failure.message] cannot be translated and never could.
/// A failure is constructed in the data layer, which has no `BuildContext`, so
/// any sentence written there is English forever — and every one of them was
/// being rendered straight into a SnackBar. Sixteen call sites did
/// `Text(f.message)`.
///
/// The fix is not to hand a BuildContext to repositories. It is to make the data
/// layer name the *reason* and let the UI choose the words — the same split
/// already used by `CartMessage`, `ReelUploadStage` and `OrderInternalStatus`
/// elsewhere in this codebase.
///
/// Exhaustively switched in `failureText`, with no fallback arm, so adding a
/// reason here without translating it is a compile error rather than an English
/// string in an Arabic UI.
enum FailureReason {
  // ── Generic ────────────────────────────────────────────────────────────
  /// The catch-all, and the default. Used where the underlying cause is a
  /// provider error with no actionable meaning for the person reading it.
  unknown,
  networkUnavailable,
  notSignedIn,

  // ── Auth ───────────────────────────────────────────────────────────────
  signInCancelled,
  signInFailed,
  guestSessionFailed,
  codeSendFailed,
  codeSendThrottled,
  codeIncorrect,
  codeExpired,
  requestCodeFirst,
  verificationFailed,
  phoneOnAnotherAccount,
  phoneLinkFailed,
  recoveryEmailFailed,

  // ── Cart and promo codes ───────────────────────────────────────────────
  promoCheckFailed,
  promoThrottled,

  // ── Chat ───────────────────────────────────────────────────────────────
  signInToMessage,
  messageTooLong,
  messagingTooFast,
  messageFailed,

  // ── Checkout ───────────────────────────────────────────────────────────
  phoneVerificationRequired,
  checkoutSetupIncomplete,
  deliveryLocationRequired,
  checkoutThrottled,
  orderFailed,

  // ── Comments ───────────────────────────────────────────────────────────
  signInToComment,
  guestCannotComment,
  commentTooLong,
  commentsBuyersOnly,
  commentingTooFast,
  commentNotAllowed,
  commentDeleteOwnOnly,
  commentPostFailed,

  // ── Legal and data export ──────────────────────────────────────────────
  documentNotPublished,
  documentLoadFailed,
  acceptanceFailed,
  dataExportFailed,

  // ── Marketplace ────────────────────────────────────────────────────────
  productsLoadFailed,
  productNotFound,
  searchFailed,
  signInToSaveProducts,

  // ── Moderation ─────────────────────────────────────────────────────────
  signInToReport,
  reportThrottled,
  reportFailed,
  chooseAnOutcome,
  notAModerator,
  reportAlreadyReviewed,
  decisionFailed,

  // ── Orders ─────────────────────────────────────────────────────────────
  orderNotFound,
  notYourOrder,
  orderAlreadyShipped,
  cancelFailed,
  ordersLoadFailed,

  // ── Profile ────────────────────────────────────────────────────────────
  sellerNotFound,
  signInToFollow,
  cannotFollowYourself,
  followThrottled,

  // ── Publishing ─────────────────────────────────────────────────────────
  signInToSell,
  guestCannotSell,
  titleRequired,
  priceRequired,
  photoRequired,
  tooManyPhotos,
  photoTooLarge,
  publishFailed,
  videoTooLong,
  uploadNeedsConnection,
  videoStillProcessing,
  publishThrottled,
  publishNotAllowed,
  uploadFailed,

  // ── Reels ──────────────────────────────────────────────────────────────
  reelsLoadFailed,
  reelNotFound,
  signInToLikeReels,
  signInToSaveReels,

  // ── Reviews ────────────────────────────────────────────────────────────
  signInToReview,
  signInToRate,
  ratingOutOfRange,
  editWindowClosed,
  rateAfterDelivery,
  itemNotInOrder,
  rateBuyersOnly,
  alreadyRated,
  reviewSubmitFailed,

  // ── Selling ────────────────────────────────────────────────────────────
  invalidStatusTransition,
  buyerCancelledOrder,
  orderMovedOn,
  orderUpdateFailed,
  statsLoadFailed,

  // ── Stock ──────────────────────────────────────────────────────────────
  outOfStock,
}

/// Domain-layer failures. The data layer converts exceptions into these so the
/// presentation layer never catches a raw FirebaseException.
sealed class Failure extends Equatable {
  const Failure(
    this.message, {
    this.code,
    this.reason = FailureReason.unknown,
    this.amount,
    this.limit,
  });

  /// **Developer-facing.** Goes to logs and Crashlytics; never rendered.
  ///
  /// It stays in English on purpose — a crash report translated into the
  /// reporter's language is harder to search, not easier. Render
  /// `failureText(context, failure)` instead, which reads [reason].
  final String message;

  /// The underlying provider's error code, where there was one, e.g.
  /// `permission-denied`. Diagnostic only.
  final String? code;

  /// What to tell the person. See [FailureReason].
  final FailureReason reason;

  /// The observed value a localized message needs, where one does — the actual
  /// length of a video that was too long, for instance.
  ///
  /// Wait times travel on [RateLimitedFailure.retryAfter] instead, because a
  /// Duration says what unit it is in and a bare int does not.
  final int? amount;

  /// The maximum that [amount] exceeded, where the message quotes it.
  ///
  /// Carried on the failure rather than read from the service that enforces it,
  /// so that translating a failure never requires `core` to import a feature.
  /// The value is still written in exactly one place — at the throw site, from
  /// the same constant the check itself used.
  final int? limit;

  @override
  List<Object?> get props => [message, code, reason, amount, limit];
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No connection',
    FailureReason reason = FailureReason.networkUnavailable,
  ]) : super(reason: reason);
}

class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    super.code,
    super.reason,
    super.amount,
    super.limit,
  });
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.reason});
}

/// Raised when a user hits checkout without a verified phone number (§5.2).
class PhoneVerificationRequiredFailure extends Failure {
  const PhoneVerificationRequiredFailure()
      : super(
          'A verified phone number is required to place an order',
          reason: FailureReason.phoneVerificationRequired,
        );
}

class RateLimitedFailure extends Failure {
  const RateLimitedFailure(
    super.message, {
    this.retryAfter,
    super.code,
    super.reason,
  });

  final Duration? retryAfter;

  @override
  List<Object?> get props => [message, code, reason, retryAfter];
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'Not found',
    FailureReason reason = FailureReason.unknown,
  ]) : super(reason: reason);
}

class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = 'Not allowed',
    FailureReason reason = FailureReason.unknown,
  ]) : super(reason: reason);
}

class OutOfStockFailure extends Failure {
  const OutOfStockFailure([super.message = 'Out of stock'])
      : super(reason: FailureReason.outOfStock);
}
