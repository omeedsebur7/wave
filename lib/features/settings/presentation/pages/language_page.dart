import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/settings/locale_controller.dart';
import 'package:wave/core/theme/app_theme.dart';

/// Language picker.
///
/// Each language is written in its own script, never translated into the current
/// one. Someone hunting for Kurdish is looking for "کوردیی ناوەندی"; rendering
/// it as "Kurdish" in Arabic helps nobody who cannot read Arabic, and that is
/// the whole population this screen exists for.
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  @override
  Widget build(BuildContext context) {
    final controller = getIt<LocaleController>();

    return Scaffold(
      appBar: AppBar(
        // Also in all three scripts: someone who has landed here by mistake in
        // a language they cannot read still needs to recognise the screen.
        title: const Text('Language · اللغة · زمان'),
      ),
      body: ListView(
        children: [
          for (final option in LocaleController.options)
            RadioListTile<String?>(
              value: option.locale?.languageCode,
              groupValue: controller.locale?.languageCode,
              onChanged: (_) async {
                await controller.setLocale(option.locale);
                if (mounted) setState(() {});
              },
              // The one row that is NOT a language name. "System default" is a
              // sentence about the phone's setting, so it is translated like
              // any other; the entries beside it are endonyms and must not be.
              title: Text(
                option.locale == null
                    ? context.l10n.systemDefault
                    : option.label,
                style: context.texts.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}
