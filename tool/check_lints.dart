import 'dart:convert';
import 'dart:io';

const _baselinePath = 'tool/lint_baseline.txt';

Future<void> main(List<String> args) async {
  final writeBaseline = args.contains('--write-baseline');

  final result = await Process.run(
    'dart',
    ['run', 'custom_lint'],
    runInShell: true,
  );

  final output = '${result.stdout}${result.stderr}';
  stdout.write(output);

  final lines = const LineSplitter().convert(output);

  bool isDiagnostic(String l) =>
      l.contains('no_raw_dimensions') ||
      l.contains('no_raw_colors') ||
      l.contains('directional_insets_only');

  final diagnostics = lines.where(isDiagnostic).toList();
  final errors = diagnostics.where((l) => l.contains('ERROR')).length;
  final warnings = diagnostics.where((l) => l.contains('WARNING')).length;

  stdout
    ..writeln()
    ..writeln('─' * 60)
    ..writeln('WAVE lints: $errors error(s), $warnings warning(s)');

  if (diagnostics.isEmpty && result.exitCode != 0 && output.contains('no_raw')) {
    stderr.writeln(
      'FAIL: custom_lint reported issues that this script could not parse. '
      'The output format may have changed.',
    );
    exit(2);
  }

  if (writeBaseline) {
    File(_baselinePath).writeAsStringSync('$warnings\n');
    stdout.writeln('Baseline written: $warnings');
    exit(0);
  }

  if (errors > 0) {
    stderr
      ..writeln()
      ..writeln(
        'FAIL: $errors violation(s) in an enforced directory. These are '
        'migrated surfaces and must not regress.',
      );
    exit(1);
  }

  final baselineFile = File(_baselinePath);
  if (!baselineFile.existsSync()) {
    stdout.writeln(
      'No baseline recorded. Run with --write-baseline to set one at $warnings.',
    );
    exit(0);
  }

  final baseline = int.tryParse(baselineFile.readAsStringSync().trim());
  if (baseline == null) {
    stderr.writeln('FAIL: $_baselinePath is not a number.');
    exit(2);
  }

  if (warnings > baseline) {
    stderr
      ..writeln()
      ..writeln('FAIL: backlog grew from $baseline to $warnings.');
    exit(1);
  }

  if (warnings < baseline) {
    stdout.writeln(
      'Backlog shrank: $baseline → $warnings. Re-baseline to lock the gain:\n'
      '  dart run tool/check_lints.dart --write-baseline',
    );
  }

  exit(0);
}
