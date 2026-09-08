import 'dart:async';

import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Without this every golden renders as boxes and the Sorani goldens prove
  // nothing at all.
  await loadAppFonts();
  return testMain();
}
