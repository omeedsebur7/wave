// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:wave_lints/src/wave_zones.dart';

class DirectionalInsetsOnly extends DartLintRule {
  const DirectionalInsetsOnly() : super(code: warning);

  static const _name = 'directional_insets_only';
  static const _problem = 'Non-directional layout. WAVE is RTL-first (P9).';
  static const _correction =
      'Use the Directional variant with start/end, e.g. '
      'EdgeInsetsDirectional.only(start:) or AlignmentDirectional.centerStart.';

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

  static const _bannedNames = {
    'left',
    'right',
    'topLeft',
    'topRight',
    'bottomLeft',
    'bottomRight',
  };

  static const _bannedConstructors = {'fromLTRB'};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final zone = zoneFor(resolver.path);
    if (zone == WaveZone.exempt) return;

    final code = zone == WaveZone.enforced ? error : warning;

    context.registry.addNamedExpression((node) {
      if (_bannedNames.contains(node.name.label.name)) {
        reporter.atNode(node, code);
      }
    });

    context.registry.addInstanceCreationExpression((node) {
      final ctor = node.constructorName.name?.name;
      if (ctor != null && _bannedConstructors.contains(ctor)) {
        reporter.atNode(node.constructorName, code);
      }
    });

    context.registry.addPrefixedIdentifier((node) {
      final prefix = node.prefix.name;
      final member = node.identifier.name.toLowerCase();

      if (prefix == 'Alignment' &&
          (member.contains('left') || member.contains('right'))) {
        reporter.atNode(node, code);
        return;
      }

      if (prefix == 'TextAlign' && (member == 'left' || member == 'right')) {
        reporter.atNode(node, code);
      }
    });
  }
}
