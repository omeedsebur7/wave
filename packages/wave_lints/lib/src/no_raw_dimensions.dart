// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:wave_lints/src/wave_zones.dart';

class NoRawDimensions extends DartLintRule {
  const NoRawDimensions() : super(code: warning);

  static const _name = 'no_raw_dimensions';
  static const _problem =
      'Raw dimension. Use context.spacing / context.surfaces / context.motion.';
  static const _correction = 'Replace the literal with a token, e.g. s.x16.';

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

  static const _watched = {
    'BorderRadius',
    'BorderRadiusDirectional',
    'BorderSide',
    'Container',
    'EdgeInsets',
    'EdgeInsetsDirectional',
    'Positioned',
    'PositionedDirectional',
    'Radius',
    'SizedBox',
  };

  static const _watchedNames = {
    'height',
    'iconSize',
    'letterSpacing',
    'size',
    'width',
  };

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
      final name = node.constructorName.type.element?.name;
      if (name == null || !_watched.contains(name)) return;

      for (final arg in node.argumentList.arguments) {
        final expr = arg is NamedExpression ? arg.expression : arg;
        if (_isOffendingLiteral(expr)) {
          reporter.atNode(expr, code);
        }
      }
    });

    context.registry.addNamedExpression((node) {
      if (!_watchedNames.contains(node.name.label.name)) return;

      if (_isArgumentOfWatchedConstructor(node)) return;

      if (_isOffendingLiteral(node.expression)) {
        reporter.atNode(node.expression, code);
      }
    });
  }

  static bool _isArgumentOfWatchedConstructor(NamedExpression node) {
    final args = node.parent;
    if (args is! ArgumentList) return false;
    final owner = args.parent;
    if (owner is! InstanceCreationExpression) return false;
    final name = owner.constructorName.type.element?.name;
    return name != null && _watched.contains(name);
  }

  static bool _isOffendingLiteral(Expression e) {
    if (e is! IntegerLiteral) return false;
    final v = e.value;
    return v != 0 && v != 1;
  }
}
