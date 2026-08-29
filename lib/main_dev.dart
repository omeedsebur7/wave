import 'package:wave/bootstrap.dart';
import 'package:wave/core/config/flavor.dart';
import 'package:wave/firebase/firebase_options_dev.dart' as dev_options;

/// Entry point for the dev flavor (project wave-dev-bb9da).
///
///     flutter run --flavor dev -t lib/main_dev.dart
///
/// This file previously imported `firebase_options_production.dart` — a
/// copy-paste of main_prod.dart edited in only one place, so `Flavor.dev` was
/// passed to bootstrap while the Firebase OPTIONS still pointed at
/// wave-prod-a529f. Flavor.isProd (which gates Crashlytics collection and
/// nothing else) would have correctly read false, but every Firestore read,
/// write and auth call would have gone to the real production project. Caught
/// before this was ever run — see the git history on this file — so nothing
/// landed there, but it is exactly the failure the Flavor enum's own doc
/// comment exists to prevent: "each maps to its own Firebase project, so
/// staging traffic can never write to production Firestore." A dev build
/// writing to production silently is the same hazard from the other
/// direction.
///
/// If `lib/firebase/firebase_options_dev.dart` does not exist yet:
///
///     flutterfire configure --project=wave-dev-bb9da \
///       --out=lib/firebase/firebase_options_dev.dart
///
/// This is a separate concern from integration_test/helpers/test_bootstrap.dart,
/// which also targets wave-dev-bb9da but deliberately does NOT use this file —
/// it resolves the project from Android's native google-services.json instead,
/// because EmulatorConfig.connect() redirects every SDK call to the local
/// emulator regardless of which options were used to initialize. A test run
/// and an actual `flutter run --flavor dev` are different enough situations
/// that sharing this file between them would be its own source of drift.
Future<void> main() async {
  await bootstrap(
    Flavor.dev,
    dev_options.DefaultFirebaseOptions.currentPlatform,
  );
}
