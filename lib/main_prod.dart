import 'package:wave/bootstrap.dart';
import 'package:wave/core/config/flavor.dart';
import 'package:wave/firebase/firebase_options_production.dart'
    as production_options;

/// Entry point for the production flavor (project wave-prod-a529f).
///
///     flutter run --flavor prod -t lib/main_prod.dart
///
/// Never wired to accept emulator overrides — see EmulatorConfig.connect,
/// which is called unconditionally from bootstrap regardless of flavor.
/// Confirm EmulatorConfig.useEmulator cannot be true for a production build
/// before shipping this; a production binary that could be pointed at a local
/// emulator via a build flag left on by accident is a production binary that
/// could be pointed anywhere.
///
/// This is the file main_dev.dart was copy-pasted from and then only
/// half-edited — it kept this import and this doc comment while main_dev.dart
/// switched only its Flavor argument, leaving a dev-labeled build pointed at
/// THIS project. If you are about to duplicate this file again for a new
/// flavor, change the import first.
Future<void> main() async {
  await bootstrap(
    Flavor.prod,
    production_options.DefaultFirebaseOptions.currentPlatform,
  );
}
