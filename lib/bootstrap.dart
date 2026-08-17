import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:wave/app/app.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/config/emulator.dart';
import 'package:wave/core/config/flavor.dart';
import 'package:wave/core/services/remote_config_service.dart';
import 'package:wave/core/services/startup_trace.dart';
import 'package:wave/features/location/data/osm_config.dart';

/// Shared startup for all three flavors.
Future<void> bootstrap(Flavor flavor) async {
  // Captured before anything else, including Firebase.initializeApp: the span
  // that matters is from the first line of Dart to the first painted frame, and
  // every await added ahead of that frame lands inside it.
  StartupTrace.markProcessStart();

  // Hold the native splash until the first real frame.
  //
  // Without this the splash disappears the moment Flutter's engine is up and
  // the user watches a blank screen while DI, Remote Config and the first feed
  // query run. Preserving it means the transition is splash → content, with no
  // gap in between — which on a cold start over a slow connection is the
  // difference between "loading" and "broken".
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // runZonedGuarded wraps everything so an async error thrown outside the
  // widget tree still reaches Crashlytics instead of vanishing.
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppConfig.flavor = flavor;

      // firebase_options_<flavor>.dart is generated per flavor by the
      // FlutterFire CLI and is gitignored. See README.
      await Firebase.initializeApp();

      // Before anything else touches Firebase — a service that has already
      // resolved its endpoint cannot be redirected afterwards.
      await EmulatorConfig.connect();

      // App Check ships WITH mandatory OTP, not after it (§1). Unprotected
      // phone auth is a well-known way to accidentally fund an SMS-pumping bot
      // farm — the attacker's revenue is your SMS bill.
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );

      // Offline persistence (§6). Cached Reel and product documents render
      // instantly on revisit without a network round-trip or a billed read.
      // Skipped under the emulator, which sets its own settings.
      if (!EmulatorConfig.useEmulator) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      FlutterError.onError = (details) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      // Crash reports from a dev build would drown the real signal.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(flavor.isProd);

      // Started once Performance exists. The wall clock was captured at the
      // top of bootstrap; this only opens the trace to attach metrics to.
      await StartupTrace.begin();
      StartupTrace.mark('firebase_ms');

      await configureDependencies();
      StartupTrace.mark('di_ms');

      await getIt<RemoteConfigService>().init();
      StartupTrace.mark('remote_config_ms');

      // Surfaces a misconfigured tile host in Crashlytics rather than waiting
      // for every map in the app to go blank at once.
      OsmConfig.warnIfMisconfigured();

      runApp(const WaveApp());

      // On the FIRST FRAME, not after runApp returns. runApp returning means
      // the widget tree was described, not that anything was painted, and the
      // gap between those two is exactly where a slow first build hides.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        StartupTrace.completeOnFirstFrame();
        // Removed here rather than after runApp: runApp returning means the
        // tree was described, not painted, and dropping the splash then shows
        // a frame of nothing.
        FlutterNativeSplash.remove();
      });
    },
    (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );
}
