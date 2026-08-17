/// Every route path and name in one place. Deep links (§5.2) are built from
/// these constants so a shared link and an in-app push can never drift apart.
abstract final class Routes {
  // Shell tabs
  static const reels = '/reels';
  static const marketplace = '/marketplace';
  static const chat = '/chat';
  static const profile = '/profile';

  // Full-screen (outside the shell)
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const phoneVerify = '/verify-phone';
  static const accountRecovery = '/recover';

  /// Internal moderation queue. Not linked from any user-facing screen; you
  /// arrive by URL and the screen refuses without the moderator claim.
  static const moderationQueue = '/internal/review-queue';
  static const forceUpdate = '/update-required';

  static const uploadReel = '/publish/reel';
  static const listProduct = '/publish/product';

  // Path TEMPLATES. Not navigated to directly — use the builders at the bottom
  // of this class. They are kept because they document the shape a deep link
  // must have, which is otherwise spread across nested `path:` segments in the
  // router and easy to get wrong.
  static const reelDetail = '/reels/:reelId';
  static const productDetail = '/marketplace/product/:productId';
  static const sellerProfile = '/seller/:sellerId';

  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/profile/orders';
  static const orderDetail = '/profile/orders/:orderId';
  static const search = '/search';
  static const sellerOrders = '/profile/selling';
  static const sellerStats = '/profile/selling/stats';
  static const notifications = '/notifications';
  static const favourites = '/profile/favourites';
  static const savedReels = '/profile/saved';
  static const notificationPrefs = '/profile/notification-settings';
  static const language = '/profile/language';
  static const legal = '/legal/:docType';

  static String legalPath(String docType) => '/legal/$docType';

  /// Reached through GoRouter's `errorBuilder`, never pushed. Kept so the path
  /// is stable if it ever needs to be linked to.
  static const notFound = '/not-found';

  static String reelDetailPath(String id) => '/reels/$id';
  static String productDetailPath(String id) => '/marketplace/product/$id';
  static String sellerProfilePath(String id) => '/seller/$id';
  static String orderDetailPath(String id) => '/profile/orders/$id';
}
