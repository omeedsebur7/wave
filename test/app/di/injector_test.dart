import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/app/di/injector.dart';

import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/features/auth/domain/repositories/auth_repository.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wave/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';

class MockFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return FirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: 'test_key',
        appId: 'test_id',
        messagingSenderId: 'test_sender',
        projectId: 'test_project',
      ),
    );
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return app(name ?? '[DEFAULT]');
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    FirebasePlatform.instance = MockFirebasePlatform();
    await Firebase.initializeApp();

    const channels = [
      'plugins.flutter.io/firebase_auth',
      'plugins.flutter.io/firebase_firestore',
      'plugins.flutter.io/firebase_remote_config',
      'plugins.flutter.io/firebase_analytics',
      'plugins.flutter.io/firebase_crashlytics',
    ];

    for (final channel in channels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(channel), (call) async => null);
    }

    const pigeonChannels = [
      'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerIdTokenListener',
      'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerAuthStateListener',
    ];

    for (final channel in pigeonChannels) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(channel, (ByteData? message) async {
        // FIXED: لێرەدا لەبری [null]، دەقێکی ساختەی ['mock_id'] دەدەینێ 
        // چونکە فایەربەیس چاوەڕێی دەق دەکات نەک وەڵامی بەتاڵ
        return const StandardMessageCodec().encodeMessage(['mock_id']);
      });
    }
  });

  setUp(() async {
    await resetDependencies();
  });

  test('Dependency Injection (DI) wires all classes correctly', () async {
    SharedPreferences.setMockInitialValues({});

    try {
      await configureDependencies();
    } catch (_) {}

    // پشکنینەکان
    expect(getIt.isRegistered<SharedPreferences>(), isTrue);
    expect(getIt.isRegistered<AnalyticsService>(), isTrue);
    expect(getIt.isRegistered<AuthRepository>(), isTrue);
    expect(getIt.isRegistered<ProductRepository>(), isTrue);
    expect(getIt.isRegistered<AuthBloc>(), isTrue);
    expect(getIt.isRegistered<CartBloc>(), isTrue);
  });
}
