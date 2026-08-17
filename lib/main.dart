// Default entrypoint points at dev so a bare `flutter run` can never
// accidentally hit the production Firebase project.
import 'package:wave/main_dev.dart' as dev;

Future<void> main() => dev.main();
