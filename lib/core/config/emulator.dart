import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase emulator wiring for integration tests and local development.
///
/// Gated behind a compile-time flag rather than a runtime check, so there is no
/// code path in a release build that can point at localhost. A test suite that
/// can accidentally run against production is a test suite that will eventually
/// delete production.
abstract final class EmulatorConfig {
  static const useEmulator =
      bool.fromEnvironment('USE_EMULATOR');

  /// Android emulators reach the host machine on 10.0.2.2, not localhost.
  static const _host = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  static const authPort = 9099;
  static const firestorePort = 8080;
  static const functionsPort = 5001;
  static const storagePort = 9199;

  static Future<void> connect() async {
    if (!useEmulator) return;

    // A release build must never talk to an emulator, flag or not.
    assert(
      !kReleaseMode,
      'USE_EMULATOR must never be set for a release build',
    );

    await FirebaseAuth.instance.useAuthEmulator(_host, authPort);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, firestorePort);
    FirebaseFunctions.instance.useFunctionsEmulator(_host, functionsPort);
    await FirebaseStorage.instance.useStorageEmulator(_host, storagePort);

    // Offline persistence caches across test runs and produces tests that pass
    // on stale data — off for the emulator.
    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: false);
  }
}
