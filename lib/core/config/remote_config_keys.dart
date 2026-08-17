/// Every server-tunable value in one place, so nothing important is hardcoded.
/// Trust-tier thresholds especially: §5.2 says tune these once real order
/// volume exists, so they must never be baked into a client release.
abstract final class RemoteConfigKeys {
  // Force-update gate (§6).
  static const minSupportedBuild = 'min_supported_build';
  static const updateUrlAndroid = 'update_url_android';
  static const updateUrlIos = 'update_url_ios';

  // Trust tiers (§5.2) — illustrative starting numbers, tuned server-side.
  static const bronzeMinOrders = 'trust_bronze_min_orders';
  static const bronzeMinRating = 'trust_bronze_min_rating';
  static const silverMinOrders = 'trust_silver_min_orders';
  static const silverMinRating = 'trust_silver_min_rating';
  static const goldMinOrders = 'trust_gold_min_orders';
  static const goldMinRating = 'trust_gold_min_rating';
  static const platinumMinOrders = 'trust_platinum_min_orders';
  static const platinumMinRating = 'trust_platinum_min_rating';

  // Feed + performance (§6).
  static const feedPageSize = 'feed_page_size';
  static const feedPrefetchThreshold = 'feed_prefetch_threshold';
  static const likeCounterShards = 'like_counter_shards';

  // Abuse protection (§1).
  static const otpMaxPerNumberPerDay = 'otp_max_per_number_per_day';
  static const otpMaxPerDevicePerDay = 'otp_max_per_device_per_day';
  static const commentCooldownSeconds = 'comment_cooldown_seconds';

  // Feature flags.
  static const commentsVerifiedPurchaseOnly = 'comments_verified_purchase_only';
  static const dataSaverDefaultOnCellular = 'data_saver_default_cellular';

  static Map<String, dynamic> get defaults => {
        minSupportedBuild: 1,
        updateUrlAndroid: '',
        updateUrlIos: '',
        bronzeMinOrders: 10,
        bronzeMinRating: 4.0,
        silverMinOrders: 50,
        silverMinRating: 4.3,
        goldMinOrders: 150,
        goldMinRating: 4.6,
        platinumMinOrders: 500,
        platinumMinRating: 4.8,
        feedPageSize: 8,
        feedPrefetchThreshold: 3,
        likeCounterShards: 10,
        otpMaxPerNumberPerDay: 5,
        otpMaxPerDevicePerDay: 10,
        commentCooldownSeconds: 15,
        // §0 Reviewer Notes: comments are open by default. Flip this flag to
        // true to match the stricter original ask without a client release.
        commentsVerifiedPurchaseOnly: false,
        dataSaverDefaultOnCellular: true,
      };
}
