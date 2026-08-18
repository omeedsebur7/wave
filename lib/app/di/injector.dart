import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/network/connectivity_service.dart';
import 'package:wave/core/services/block_list.dart';
import 'package:wave/core/services/bunny_stream_service.dart';
import 'package:wave/core/services/force_update_service.dart';
import 'package:wave/core/services/remote_config_service.dart';
import 'package:wave/core/services/sharded_counter_service.dart';
import 'package:wave/core/services/write_throttle.dart';
import 'package:wave/core/settings/locale_controller.dart';
import 'package:wave/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:wave/features/auth/domain/repositories/auth_repository.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wave/features/cart/data/cart_store.dart';
import 'package:wave/features/cart/data/promo_repository.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:wave/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:wave/features/checkout/data/datasources/saved_details_data_source.dart';
import 'package:wave/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:wave/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:wave/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:wave/features/checkout/presentation/bloc/quick_checkout_cubit.dart';
import 'package:wave/features/comments/data/repositories/comment_repository_impl.dart';
import 'package:wave/features/comments/domain/repositories/comment_repository.dart';
import 'package:wave/features/legal/data/data_export_service.dart';
import 'package:wave/features/legal/data/legal_repository.dart';
import 'package:wave/features/location/data/saved_location_store.dart';
import 'package:wave/features/marketplace/data/repositories/product_repository_impl.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';
import 'package:wave/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:wave/features/marketplace/presentation/bloc/product_detail_bloc.dart';
import 'package:wave/features/moderation/data/moderation_repository.dart';
import 'package:wave/features/notifications/data/push_handler.dart';
import 'package:wave/features/notifications/data/repositories/notification_repository.dart';
import 'package:wave/features/onboarding/data/onboarding_service.dart';
import 'package:wave/features/orders/data/repositories/order_repository_impl.dart';
import 'package:wave/features/orders/domain/repositories/order_repository.dart';
import 'package:wave/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:wave/features/profile/data/repositories/seller_profile_repository.dart';
import 'package:wave/features/publish/data/product_publish_service.dart';
import 'package:wave/features/publish/data/reel_upload_service.dart';
import 'package:wave/features/reels/data/buy_now_tracker.dart';
import 'package:wave/features/reels/data/datasources/reel_remote_data_source.dart';
import 'package:wave/features/reels/data/repositories/reel_repository_impl.dart';
import 'package:wave/features/reels/domain/repositories/reel_repository.dart';
import 'package:wave/features/reels/presentation/bloc/reels_feed_bloc.dart';
import 'package:wave/features/reviews/data/repositories/review_repository_impl.dart';
import 'package:wave/features/reviews/domain/repositories/review_repository.dart';
import 'package:wave/features/search/presentation/bloc/search_bloc.dart';
import 'package:wave/features/selling/data/repositories/seller_order_repository_impl.dart';
import 'package:wave/features/selling/data/seller_stats_repository.dart';
import 'package:wave/features/selling/domain/repositories/seller_order_repository.dart';
import 'package:wave/features/selling/presentation/bloc/seller_orders_bloc.dart';

final getIt = GetIt.instance;

/// Dependency wiring, registered by hand.
///
/// The brief specifies GetIt + Injectable, and the `@injectable` annotations
/// are still on every class so switching to generated wiring is a build_runner
/// run away. This file exists because hand-written registration has one
/// property generated code does not: it runs on a fresh clone, before any
/// codegen, so `flutter run` works immediately. It's also the file a new
/// engineer reads to understand what depends on what — a generated one teaches
/// nobody anything.
///
/// The cost of that choice is this file: positional `getIt()` calls carry no
/// type information at the call site, so a constructor losing a parameter
/// surfaces as an arity error here rather than being regenerated. Worth
/// knowing which trade you are making.
///
/// Lifetimes, and why:
///
/// - **lazySingleton** for anything holding a connection, a cache, or shared
///   state: repositories, services, and the cart. One instance, created on
///   first use.
/// - **factory** for BLoCs tied to a screen. A new instance per page means
///   closing a page disposes its state instead of leaking it into the next
///   visit — except CartBloc, which is a singleton precisely because the nav
///   badge, the Buy Now sheet and the cart page must all agree.
Future<void> configureDependencies() async {
  // SharedPreferences is async to obtain, so it is resolved here rather than
  // registered lazily — a lazy singleton returning a Future would force every
  // call site to await it.
  final prefs = await SharedPreferences.getInstance();
  getIt
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<OnboardingService>(OnboardingService(prefs))
    ..registerSingleton<LocaleController>(LocaleController(prefs))
    ..registerSingleton<CartStore>(CartStore(prefs))
    ..registerSingleton<SavedLocationStore>(SavedLocationStore(prefs));

  _registerFirebase();
  _registerCoreServices();
  _registerRepositories();
  _registerBlocs();

  // Anything that must be warm before the first frame is awaited here rather
  // than lazily on first use, so the UI never renders against empty config.
  await getIt<RemoteConfigService>().init();
}

void _registerFirebase() {
  getIt
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance)
    ..registerLazySingleton<FirebaseFunctions>(() => FirebaseFunctions.instance)
    ..registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance)
    ..registerLazySingleton<FirebaseCrashlytics>(
      () => FirebaseCrashlytics.instance,
    )
    ..registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance)
    ..registerLazySingleton<FirebaseRemoteConfig>(
      () => FirebaseRemoteConfig.instance,
    )
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ),
    );
}

void _registerCoreServices() {
  getIt
    ..registerLazySingleton<AnalyticsService>(
      () => FirebaseAnalyticsService(getIt(), getIt()),
    )
    ..registerLazySingleton<ConnectivityService>(
      () => ConnectivityService(getIt()),
      dispose: (service) => service.dispose(),
    )
    ..registerLazySingleton<RemoteConfigService>(
      () => RemoteConfigService(getIt()),
    )
    ..registerLazySingleton<ForceUpdateService>(
      () => ForceUpdateService(getIt()),
    )
    // Eagerly constructed: it subscribes to the block list on creation, and a
    // lazily-created one would let the first feed page render unfiltered.
    ..registerSingleton<BlockList>(BlockList(getIt(), getIt()))
    ..registerLazySingleton<PromoRepository>(() => PromoRepository(getIt()))
    ..registerLazySingleton<WriteThrottle>(
      () => WriteThrottle(getIt(), getIt()),
    )
    // RemoteConfigService only. The service takes the parent DocumentReference
    // as an argument to every method and derives the shard collection from it,
    // so it never needed a FirebaseFirestore handle of its own — that second
    // getIt() was resolving a dependency the class had already stopped using.
    ..registerLazySingleton<ShardedCounterService>(
      () => ShardedCounterService(getIt()),
    )
    ..registerLazySingleton<BunnyStreamService>(
      () => BunnyStreamService(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<ReelUploadService>(
      () => ReelUploadService(getIt(), getIt()),
    )
    ..registerLazySingleton<ProductPublishService>(
      () => ProductPublishService(getIt(), getIt(), getIt()),
    );
}

void _registerRepositories() {
  getIt
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt(), getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<BuyNowTracker>(
      () => BuyNowTracker(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<ReelRemoteDataSource>(
      () => ReelRemoteDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<ReelRepository>(
      () => ReelRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<ProductRepository>(
      () => ProductRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<OrderRepository>(
      () => OrderRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<ReviewRepository>(
      () => ReviewRepositoryImpl(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<CheckoutRepository>(
      () => CheckoutRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<ChatRepository>(
      () => ChatRepository(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<NotificationRepository>(
      () => NotificationRepository(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<CommentRepository>(
      () => CommentRepositoryImpl(
        getIt(),
        getIt(),
        getIt(),
        getIt(),
        getIt(),
      ),
    )
    ..registerLazySingleton<SellerProfileRepository>(
      () => SellerProfileRepository(getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<SavedDetailsDataSource>(
      () => SavedDetailsDataSource(getIt(), getIt()),
    )
    ..registerLazySingleton<DataExportService>(
      () => DataExportService(getIt()),
    )
    ..registerLazySingleton<LegalRepository>(
      () => LegalRepository(getIt(), getIt()),
    )
    ..registerLazySingleton<SellerOrderRepository>(
      () => SellerOrderRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<SellerStatsRepository>(
      () => SellerStatsRepository(getIt(), getIt()),
    )
    ..registerLazySingleton<ModerationRepository>(
      () => ModerationRepository(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<PushHandler>(
      () => PushHandler(getIt(), getIt()),
    );
}

void _registerBlocs() {
  getIt
    // Singleton: the nav badge, the Buy Now sheet and the cart page must never
    // disagree about what is in the cart.
    ..registerLazySingleton<CartBloc>(
      () => CartBloc(getIt(), getIt(), getIt()),
    )
    // Singleton: auth state is global, and a second instance would mean two
    // sources of truth about who is signed in.
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(getIt(), getIt(), getIt()),
    )
    ..registerFactory<ReelsFeedBloc>(
      () => ReelsFeedBloc(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerFactory<MarketplaceBloc>(() => MarketplaceBloc(getIt()))
    ..registerFactory<ProductDetailBloc>(
      () => ProductDetailBloc(getIt(), getIt()),
    )
    ..registerFactory<OrdersBloc>(() => OrdersBloc(getIt()))
    ..registerFactory<SellerOrdersBloc>(() => SellerOrdersBloc(getIt()))
    ..registerFactory<SearchBloc>(() => SearchBloc(getIt(), getIt(), getIt()))
    // Factory is load-bearing for both checkout paths: each instance mints its
    // own idempotency key. A singleton would reuse the key across two separate
    // purchases, and the second order would come back as a silent no-op
    // returning the first order — the buyer sees a success screen for something
    // that was never placed.
    ..registerFactory<QuickCheckoutCubit>(
      () => QuickCheckoutCubit(getIt(), getIt()),
    )
    ..registerFactory<CheckoutBloc>(() => CheckoutBloc(getIt(), getIt()));
}

/// Test helper: drop everything so each test starts from a clean container.
Future<void> resetDependencies() => getIt.reset();
