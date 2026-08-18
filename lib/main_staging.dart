import 'package:wave/bootstrap.dart';
import 'package:wave/core/config/flavor.dart';
import 'package:wave/firebase/firebase_options_staging.dart' as staging_options;

/// Entry point for the staging flavor (project wave-staging-d1b41).
///
///     flutter run --flavor staging -t lib/main_staging.dart
Future<void> main() async {
  await bootstrap(Flavor.staging, staging_options.DefaultFirebaseOptions.currentPlatform);
}
