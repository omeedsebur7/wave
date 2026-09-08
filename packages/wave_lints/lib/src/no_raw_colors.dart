// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:wave_lints/src/wave_zones.dart';

class NoRawColors extends DartLintRule {
  const NoRawColors() : super(code: warning);

  static const _name = 'no_raw_colors';
  static const _problem = 'Raw colour. Use context.waveColors.';
  static const _correction =
      'Replace with a semantic token, e.g. c.surface or c.textPrimary.';

  static const warning = LintCode(
    name: _name,
    problemMessage: _problem,
    correctionMessage: _correction,
    errorSeverity: ErrorSeverity.WARNING,
  );

  static const error = LintCode(
    name: _name,
    problemMessage: _problem,
    correctionMessage: _correction,
    errorSeverity: ErrorSeverity.ERROR,
  );

  static const _allowed = {'transparent', 'white', 'black54', 'black'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final zone = zoneFor(resolver.path);
    if (zone == WaveZone.exempt) return;

    final code = zone == WaveZone.enforced ? error : warning;

    context.registry.addInstanceCreationExpression((node) {
      if (node.constructorName.type.element?.name == 'Color') {
        reporter.atNode(node, code);
      }
    });

    context.registry.addPrefixedIdentifier((node) {
      final prefix = node.prefix.name;
      if (prefix != 'Colors' && prefix != 'CupertinoColors') return;
      if (_allowed.contains(node.identifier.name)) return;
      reporter.atNode(node, code);
    });
  }
}
