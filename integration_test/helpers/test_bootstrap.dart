import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:wave/core/config/emulator.dart';

Future<void> initializeIntegrationFirebase() async {
  const useEmulator = bool.fromEnvironment('USE_EMULATOR');

  if (!useEmulator) {
    throw StateError(
      'Integration tests require --dart-define=USE_EMULATOR=true.',
    );
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // Configure every Firebase client before any service is used.
  await EmulatorConfig.connect();

  // Fail fast if the test did not actually select the Android emulator.
  if (kIsWeb) {
    throw StateError(
      'This integration suite is currently intended for Android Emulator.',
    );
  }
}