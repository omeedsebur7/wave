import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/utils/result.dart';

/// Data export (§7).
///
/// Writes the JSON to a temp file and opens the platform share sheet rather
/// than emailing it or putting it behind a download link. The person asked for
/// their data; handing it straight to them, in a format they can open, is the
/// least ceremonious way to actually comply.
class DataExportService {
  DataExportService(this._functions);

  final FirebaseFunctions _functions;

  /// [shareSubject] is passed in for the same reason the receipt strings are:
  /// a service has no BuildContext, and a share sheet titled in the wrong
  /// language is the first thing the recipient sees.
  Future<Result<File>> exportAndShare({required String shareSubject}) async {
    try {
      final result = await _functions
          .httpsCallable('exportMyData')
          .call<Map<String, dynamic>>();

      // Pretty-printed on purpose. An export nobody can read is compliance
      // theatre — the point is that the person can actually inspect it.
      final json = const JsonEncoder.withIndent('  ').convert(result.data);

      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().split('T').first;
      final file = File('${dir.path}/wave-my-data-$stamp.json');
      await file.writeAsString(json);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: shareSubject,
      );

      return Success(file);
    } on FirebaseFunctionsException catch (e) {
      return Err(
        ServerFailure(
          e.message ?? 'Export failed',
          code: e.code,
          reason: FailureReason.dataExportFailed,
        ),
      );
    } catch (e) {
      return Err(
        ServerFailure(
          'Could not prepare your data: $e',
          reason: FailureReason.dataExportFailed,
        ),
      );
    }
  }
}
