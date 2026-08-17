import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/app/widgets/wave_shell.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/auth/presentation/pages/account_recovery_page.dart';
import 'package:wave/features/auth/presentation/pages/phone_verify_page.dart';
import 'package:wave/features/auth/presentation/pages/sign_in_page.dart';
import 'package:wave/features/cart/presentation/pages/cart_page.dart';
import 'package:wave/features/chat/presentation/pages/chat_list_page.dart';
import 'package:wave/features/checkout/presentation/pages/checkout_page.dart';
import 'package:wave/features/legal/domain/legal_document.dart';
import 'package:wave/features/legal/presentation/pages/force_update_page.dart';
import 'package:wave/features/legal/presentation/pages/legal_document_page.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/presentation/pages/favourites_page.dart';
import 'package:wave/features/marketplace/presentation/pages/marketplace_page.dart';
import 'package:wave/features/marketplace/presentation/pages/product_detail_page.dart';
import 'package:wave/features/moderation/presentation/pages/moderation_queue_page.dart';
import 'package:wave/features/notifications/presentation/pages/notification_center_page.dart';
import 'package:wave/features/notifications/presentation/pages/notification_prefs_page.dart';
import 'package:wave/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:wave/features/orders/presentation/pages/order_detail_page.dart';
import 'package:wave/features/orders/presentation/pages/orders_page.dart';
import 'package:wave/features/profile/presentation/pages/profile_page.dart';
import 'package:wave/features/profile/presentation/pages/seller_profile_page.dart';
import 'package:wave/features/publish/presentation/pages/list_product_page.dart';
import 'package:wave/features/publish/presentation/pages/upload_reel_page.dart';
import 'package:wave/features/reels/presentation/pages/reels_page.dart';
import 'package:wave/features/reels/presentation/pages/saved_reels_page.dart';
import 'package:wave/features/search/presentation/pages/search_page.dart';
import 'package:wave/features/selling/presentation/pages/seller_orders_page.dart';
import 'package:wave/features/selling/presentation/pages/seller_stats_page.dart';
import 'package:wave/features/settings/presentation/pages/language_page.dart';

/// GoRouter setup (§2).
///
/// StatefulShellRoute gives each of the four tabs its own Navigator, so
/// scrolling three products deep in Marketplace, switching to Chat, and coming
/// back leaves you exactly where you were. That's the behaviour users expect
/// and it's very hard to bolt on afterwards.
class AppRouter {
  AppRouter({
    required this.isSignedIn,
    required this.needsForceUpdate,
    required this.hasSeenOnboarding,
    this.refreshListenable,
  });

  final bool Function() isSignedIn;
  final bool Function() needsForceUpdate;

  /// First-run gate. Read through a callback rather than captured once, so
  /// completing the walkthrough takes effect on the next redirect without
  /// rebuilding the router.
  final bool Function() hasSeenOnboarding;

  /// Re-runs the redirect logic whenever auth state changes, so signing in
  /// from a deep-linked checkout returns the user to checkout rather than
  /// dumping them on the feed.
  final Listenable? refreshListenable;

  static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final _reelsKey = GlobalKey<NavigatorState>(debugLabel: 'reels');
  static final _marketKey = GlobalKey<NavigatorState>(debugLabel: 'market');
  static final _chatKey = GlobalKey<NavigatorState>(debugLabel: 'chat');
  static final _profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

  late final GoRouter router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.reels,
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,
    // Screen views, recorded once here rather than in forty widgets. Anything
    // per-screen is a line somebody forgets on the forty-first.
    observers: [_ScreenViewObserver(getIt<AnalyticsService>())],

    // Invalid or expired deep links land on a real error route with a way out,
    // never a blank screen or a crash (§2).
    errorBuilder: (context, state) => Scaffold(
      body: WaveErrorView(
        title: context.l10n.errorDeadLink,
        message: context.l10n.errorDeadLinkBody,
        retryLabel: context.l10n.goToReels,
        icon: Icons.link_off,
        onRetry: () => context.go(Routes.reels),
      ),
    ),

    redirect: (context, state) {
      // A blocked build can't route anywhere except the update wall.
      if (needsForceUpdate() && state.matchedLocation != Routes.forceUpdate) {
        return Routes.forceUpdate;
      }

      // First run. Checked after the update wall — an unsupported build should
      // not walk someone through a product they cannot use — and before auth,
      // since the walkthrough deliberately runs before any sign-in.
      if (!hasSeenOnboarding() &&
          state.matchedLocation != Routes.onboarding) {
        return Routes.onboarding;
      }
      // Guest mode is deliberately permissive: browsing Reels and the
      // Marketplace never requires an account (§1). Only checkout does, and
      // that gate lives on the checkout route itself rather than here, so a
      // guest never gets bounced out of discovery.
      const authOnly = [Routes.checkout, Routes.orders, Routes.uploadReel];
      final needsAuth =
          authOnly.any((r) => state.matchedLocation.startsWith(r));
      if (needsAuth && !isSignedIn()) {
        return '${Routes.signIn}?from=${state.matchedLocation}';
      }
      return null;
    },

    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) =>
            SignInPage(returnTo: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: Routes.accountRecovery,
        builder: (_, __) => const AccountRecoveryPage(),
      ),
      GoRoute(
        path: Routes.moderationQueue,
        builder: (_, __) => const ModerationQueuePage(),
      ),
      GoRoute(
        path: Routes.forceUpdate,
        builder: (_, __) => const ForceUpdatePage(),
      ),
      GoRoute(
        path: Routes.phoneVerify,
        builder: (context, state) => PhoneVerifyPage(
          reason: switch (state.uri.queryParameters['reason']) {
            'checkout' => PhoneVerifyReason.checkoutGate,
            'recovery' => PhoneVerifyReason.recovery,
            _ => PhoneVerifyReason.signIn,
          },
          returnTo: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: Routes.legal,
        builder: (context, state) => LegalDocumentPage(
          docType: LegalDocType.fromSlug(
            state.pathParameters['docType'] ?? 'terms',
          ),
        ),
      ),
      // Outside the shell so a seller profile opened from a Reel, a product or
      // a deep link behaves the same way in all three cases.
      GoRoute(
        path: Routes.sellerProfile,
        builder: (context, state) => SellerProfilePage(
          sellerId: state.pathParameters['sellerId']!,
        ),
      ),
      GoRoute(path: Routes.search, builder: (_, __) => const SearchPage()),
      GoRoute(
        path: Routes.sellerOrders,
        builder: (_, __) => const SellerOrdersPage(),
      ),
      GoRoute(
        path: Routes.sellerStats,
        builder: (_, __) => const SellerStatsPage(),
      ),
      GoRoute(path: Routes.cart, builder: (_, __) => const CartPage()),
      GoRoute(
        path: Routes.checkout,
        builder: (context, state) => CheckoutPage(
          sourceReelId: state.uri.queryParameters['reel'],
        ),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const NotificationCenterPage(),
      ),
      GoRoute(
        path: Routes.uploadReel,
        builder: (_, __) => const UploadReelPage(),
      ),
      GoRoute(
        path: Routes.listProduct,
        builder: (_, __) => const ListProductPage(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => WaveShell(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _reelsKey,
            routes: [
              GoRoute(
                path: Routes.reels,
                builder: (_, __) => const ReelsPage(),
                routes: [
                  GoRoute(
                    path: ':reelId',
                    builder: (context, state) => ReelsPage(
                      initialReelId: state.pathParameters['reelId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _marketKey,
            routes: [
              GoRoute(
                path: Routes.marketplace,
                builder: (_, __) => const MarketplacePage(),
                routes: [
                  GoRoute(
                    path: 'product/:productId',
                    builder: (context, state) => ProductDetailPage(
                      productId: state.pathParameters['productId']!,
                      // Present when navigated from the grid, absent on a cold
                      // deep link — the page handles both.
                      preloaded: state.extra as Product?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _chatKey,
            routes: [
              GoRoute(path: Routes.chat, builder: (_, __) => const ChatListPage()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileKey,
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, __) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'orders',
                    builder: (_, __) => const OrdersPage(),
                    routes: [
                      GoRoute(
                        path: ':orderId',
                        builder: (context, state) => OrderDetailPage(
                          orderId: state.pathParameters['orderId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'favourites',
                    builder: (_, __) => const FavouritesPage(),
                  ),
                  GoRoute(
                    path: 'saved',
                    builder: (context, state) => SavedReelsPage(
                      savedReelIds: (state.extra as List<String>?) ?? const [],
                    ),
                  ),
                  GoRoute(
                    path: 'notification-settings',
                    builder: (_, __) => const NotificationPrefsPage(),
                  ),
                  GoRoute(
                    path: 'language',
                    builder: (_, __) => const LanguagePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Reports screen views to Analytics from one place.
///
/// Uses the route PATH, not the widget name, so a screen renamed in code keeps
/// the same analytics identity — otherwise a refactor silently splits a funnel
/// in two.
class _ScreenViewObserver extends NavigatorObserver {
  _ScreenViewObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previous) =>
      _report(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previous) =>
      _report(previous);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _report(newRoute);

  void _report(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null || name.isEmpty) return;
    // Strip path parameters: '/reels/abc123' and '/reels/def456' are the same
    // screen, and keeping the ids would produce thousands of one-view screens.
    final normalised = name.replaceAll(RegExp('/[a-zA-Z0-9_-]{16,}'), '/:id');
    _analytics.screen(normalised);
  }
}
