import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'package:wave_lints/src/directional_insets_only.dart';
import 'package:wave_lints/src/no_raw_colors.dart';
import 'package:wave_lints/src/no_raw_dimensions.dart';

PluginBase createPlugin() => _WaveLints();

class _WaveLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
        NoRawDimensions(),
        NoRawColors(),
        DirectionalInsetsOnly(),
      ];
}
