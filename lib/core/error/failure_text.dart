import 'package:flutter/widgets.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/l10n_extension.dart';

/// Turns a [Failure] into words the person can read, in their own language.
///
/// This is the only place a failure becomes text. Every `SnackBar`, dialog and
/// error view goes through it, because the alternative — `Text(failure.message)`
/// — renders a sentence written in the data layer, and the data layer has no
/// `BuildContext` and therefore no language. Sixteen call sites did exactly that
/// before this existed.
///
/// The switch is exhaustive with no `_` arm on purpose. Adding a
/// [FailureReason] without translating it should stop the build, not ship an
/// English string into an Arabic UI — the failure mode this whole file exists to
/// remove.
String failureText(BuildContext context, Failure failure) {
  final l10n = context.l10n;

  return switch (failure.reason) {
    // ── Generic ────────────────────────────────────────────────────────────
    //
    // `unknown` is the default, so it is also what every provider error with no
    // actionable meaning lands on. It deliberately says nothing about the cause:
    // `e.message` from Firebase is untranslated English at best, and an internal
    // rule name at worst.
    FailureReason.unknown => l10n.errorGeneric,
    FailureReason.networkUnavailable => l10n.errorNoConnectionBody,
    FailureReason.notSignedIn => l10n.errorNotSignedIn,

    // ── Auth ───────────────────────────────────────────────────────────────
    FailureReason.signInCancelled => l10n.errorSignInCancelled,
    FailureReason.signInFailed => l10n.errorSignInFailed,
    FailureReason.guestSessionFailed => l10n.errorGuestSessionFailed,
    FailureReason.codeSendFailed => l10n.errorCodeSendFailed,
    FailureReason.codeSendThrottled =>
      l10n.errorCodeSendThrottled(_waitMinutes(failure)),
    FailureReason.codeIncorrect => l10n.errorCodeIncorrect,
    FailureReason.codeExpired => l10n.errorCodeExpired,
    FailureReason.requestCodeFirst => l10n.errorRequestCodeFirst,
    FailureReason.verificationFailed => l10n.errorVerificationFailed,
    FailureReason.phoneOnAnotherAccount => l10n.errorPhoneOnAnotherAccount,
    FailureReason.phoneLinkFailed => l10n.errorPhoneLinkFailed,
    FailureReason.recoveryEmailFailed => l10n.errorRecoveryEmailFailed,

    // ── Cart and promo codes ───────────────────────────────────────────────
    FailureReason.promoCheckFailed => l10n.errorPromoCheckFailed,
    FailureReason.promoThrottled => l10n.promoTooManyAttempts,

    // ── Chat ───────────────────────────────────────────────────────────────
    FailureReason.signInToMessage => l10n.errorSignInToMessage,
    FailureReason.messageTooLong => l10n.errorMessageTooLong,
    FailureReason.messagingTooFast => l10n.errorMessagingTooFast,
    FailureReason.messageFailed => l10n.errorMessageFailed,

    // ── Checkout ───────────────────────────────────────────────────────────
    FailureReason.phoneVerificationRequired => l10n.errorVerifyPhoneToOrder,
    FailureReason.checkoutSetupIncomplete => l10n.errorCheckoutSetupIncomplete,
    FailureReason.deliveryLocationRequired =>
      l10n.errorDeliveryLocationRequired,
    FailureReason.checkoutThrottled => l10n.errorTooManyAttempts,
    FailureReason.orderFailed => l10n.errorOrderFailed,

    // ── Comments ───────────────────────────────────────────────────────────
    FailureReason.signInToComment => l10n.errorSignInToComment,
    FailureReason.guestCannotComment => l10n.errorGuestCannotComment,
    FailureReason.commentTooLong => l10n.errorCommentTooLong,
    FailureReason.commentsBuyersOnly => l10n.errorCommentsBuyersOnly,
    FailureReason.commentingTooFast =>
      l10n.errorCommentingTooFast(_waitSeconds(failure)),
    FailureReason.commentNotAllowed => l10n.errorCommentNotAllowed,
    FailureReason.commentDeleteOwnOnly => l10n.errorCommentDeleteOwnOnly,
    FailureReason.commentPostFailed => l10n.errorCommentPostFailed,

    // ── Legal and data export ──────────────────────────────────────────────
    //
    // Deliberately does not name the document. The page raising this already
    // has its title in the app bar, and naming it here would mean either
    // carrying a feature enum into `core` or interpolating the developer-facing
    // `message` — which is the English sentence this file exists to stop
    // rendering.
    FailureReason.documentNotPublished => l10n.errorDocumentNotPublished,
    FailureReason.documentLoadFailed => l10n.errorDocumentLoadFailed,
    FailureReason.acceptanceFailed => l10n.errorAcceptanceFailed,
    FailureReason.dataExportFailed => l10n.errorDataExportFailed,

    // ── Marketplace ────────────────────────────────────────────────────────
    FailureReason.productsLoadFailed => l10n.errorProductsLoadFailed,
    FailureReason.productNotFound => l10n.productNotFound,
    FailureReason.searchFailed => l10n.errorSearchFailed,
    FailureReason.signInToSaveProducts => l10n.errorSignInToSaveProducts,

    // ── Moderation ─────────────────────────────────────────────────────────
    FailureReason.signInToReport => l10n.errorSignInToReport,
    FailureReason.reportThrottled =>
      l10n.errorReportThrottled(_waitSeconds(failure)),
    FailureReason.reportFailed => l10n.errorReportFailed,
    FailureReason.chooseAnOutcome => l10n.errorChooseAnOutcome,
    FailureReason.notAModerator => l10n.errorNotAModerator,
    FailureReason.reportAlreadyReviewed => l10n.errorReportAlreadyReviewed,
    FailureReason.decisionFailed => l10n.errorDecisionFailed,

    // ── Orders ─────────────────────────────────────────────────────────────
    FailureReason.orderNotFound => l10n.orderNotFound,
    FailureReason.notYourOrder => l10n.errorNotYourOrder,
    FailureReason.orderAlreadyShipped => l10n.errorOrderAlreadyShipped,
    FailureReason.cancelFailed => l10n.errorCancelFailed,
    FailureReason.ordersLoadFailed => l10n.ordersNotLoaded,

    // ── Profile ────────────────────────────────────────────────────────────
    FailureReason.sellerNotFound => l10n.sellerNotFound,
    FailureReason.signInToFollow => l10n.errorSignInToFollow,
    FailureReason.cannotFollowYourself => l10n.errorCannotFollowYourself,
    FailureReason.followThrottled =>
      l10n.errorFollowThrottled(_waitSeconds(failure)),

    // ── Publishing ─────────────────────────────────────────────────────────
    //
    // The quoted limits ride on the failure rather than being read from the
    // services that enforce them, so translating a failure never drags a
    // feature import into `core`. Each is still written once, at the throw
    // site, from the same constant the check used.
    FailureReason.signInToSell => l10n.errorSignInToSell,
    FailureReason.guestCannotSell => l10n.errorGuestCannotSell,
    FailureReason.titleRequired => l10n.errorTitleRequired,
    FailureReason.priceRequired => l10n.errorPriceRequired,
    FailureReason.photoRequired => l10n.errorPhotoRequired,
    FailureReason.tooManyPhotos => l10n.errorTooManyPhotos(failure.limit ?? 0),
    FailureReason.photoTooLarge =>
      l10n.errorPhotoTooLarge(failure.limit ?? 0),
    FailureReason.publishFailed => l10n.errorPublishFailed,
    FailureReason.videoTooLong =>
      l10n.videoTooLong(failure.amount ?? 0, failure.limit ?? 0),
    FailureReason.uploadNeedsConnection => l10n.errorUploadNeedsConnection,
    FailureReason.videoStillProcessing => l10n.errorVideoStillProcessing,
    FailureReason.publishThrottled => l10n.errorPublishThrottled,
    FailureReason.publishNotAllowed => l10n.errorPublishNotAllowed,
    FailureReason.uploadFailed => l10n.errorUploadFailed,

    // ── Reels ──────────────────────────────────────────────────────────────
    FailureReason.reelsLoadFailed => l10n.reelsNotLoaded,
    FailureReason.reelNotFound => l10n.errorReelNotFound,
    FailureReason.signInToLikeReels => l10n.errorSignInToLikeReels,
    FailureReason.signInToSaveReels => l10n.errorSignInToSaveReels,

    // ── Reviews ────────────────────────────────────────────────────────────
    FailureReason.signInToReview => l10n.errorSignInToReview,
    FailureReason.signInToRate => l10n.errorSignInToRate,
    FailureReason.ratingOutOfRange => l10n.errorRatingOutOfRange,
    FailureReason.editWindowClosed => l10n.errorEditWindowClosed,
    FailureReason.rateAfterDelivery => l10n.errorRateAfterDelivery,
    FailureReason.itemNotInOrder => l10n.errorItemNotInOrder,
    FailureReason.rateBuyersOnly => l10n.errorRateBuyersOnly,
    FailureReason.alreadyRated => l10n.errorAlreadyRated,
    FailureReason.reviewSubmitFailed => l10n.errorReviewSubmitFailed,

    // ── Selling ────────────────────────────────────────────────────────────
    FailureReason.invalidStatusTransition => l10n.errorInvalidStatusTransition,
    FailureReason.buyerCancelledOrder => l10n.errorBuyerCancelledOrder,
    FailureReason.orderMovedOn => l10n.errorOrderMovedOn,
    FailureReason.orderUpdateFailed => l10n.errorOrderUpdateFailed,
    FailureReason.statsLoadFailed => l10n.statsNotLoaded,

    // ── Stock ──────────────────────────────────────────────────────────────
    FailureReason.outOfStock => l10n.errorSoldOutDuringCheckout,
  };
}

/// Whole seconds to wait, rounded up and never below one.
///
/// "Try again in 0s" reads as a bug, and it is what truncation produces for any
/// wait under a second — which is most of them, since these are token-bucket
/// remainders.
int _waitSeconds(Failure failure) {
  final retryAfter = failure is RateLimitedFailure ? failure.retryAfter : null;
  if (retryAfter == null) return 1;
  return retryAfter.inSeconds + 1;
}

int _waitMinutes(Failure failure) {
  final retryAfter = failure is RateLimitedFailure ? failure.retryAfter : null;
  if (retryAfter == null) return 1;
  return retryAfter.inMinutes + 1;
}
