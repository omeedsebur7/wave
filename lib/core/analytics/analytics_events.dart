/// Custom event taxonomy (§6 — Observability).
///
/// Named constants rather than string literals at call sites, because a typo in
/// an analytics event name is invisible until you try to build the funnel three
/// months later and half the data is missing.
abstract final class AnalyticsEvents {
  // Buy-Now-on-Reel funnel (§5.1) — the chain that has to join against orders.
  static const reelViewed = 'reel_viewed';
  static const buyNowTapped = 'buy_now_tapped';
  static const quickCheckoutOpened = 'quick_checkout_opened';
  static const purchaseCompleted = 'purchase_completed';

  // Auth + identity gate.
  static const signUpCompleted = 'sign_up_completed';
  static const guestUpgraded = 'guest_upgraded';
  static const otpRequested = 'otp_requested';
  static const otpVerificationCompleted = 'otp_verification_completed';
  static const checkoutGateShown = 'checkout_gate_shown';

  // Trust + reviews.
  static const reviewSubmitted = 'review_submitted';
  static const sellerRatingSubmitted = 'seller_rating_submitted';
  static const trustBadgeViewed = 'trust_badge_viewed';

  // Orders.
  static const orderTrackerViewed = 'order_tracker_viewed';
  static const orderCancelled = 'order_cancelled';

  // Publishing + social.
  static const reelPublished = 'reel_published';
  static const productLinkedToReel = 'product_linked_to_reel';
  static const contentReported = 'content_reported';

  // Performance guardrails.
  static const videoTimeToFirstFrame = 'video_time_to_first_frame';
  static const feedPageLoaded = 'feed_page_loaded';
}

abstract final class AnalyticsParams {
  static const reelId = 'reel_id';
  static const productId = 'product_id';
  static const sellerId = 'seller_id';
  static const orderId = 'order_id';
  static const value = 'value';
  static const currency = 'currency';
  static const trustTier = 'trust_tier';
  static const source = 'source';
  static const durationMs = 'duration_ms';
}
