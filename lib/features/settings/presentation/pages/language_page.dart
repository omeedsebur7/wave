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
      // RadioGroup replaces the per-tile groupValue/onChanged pair deprecated
      // after Flutter 3.32.
      //
      // Typed RadioGroup<String> rather than <String?>. We use the sentinel
      // value 'system' to represent the system default locale (which is null
      // in LocaleController). This prevents a dangerous overlap: RadioGroup
      // passes null to onChanged when a selection is cleared (e.g. if a future
      // developer adds toggleable: true). By using a sentinel, a null from
      // onChanged unambiguously means "cleared" (which we can safely ignore).
      body: RadioGroup<String>(
        groupValue: controller.locale?.languageCode ?? 'system',
        onChanged: (code) async {
          // A null code now unambiguously means the selection was cleared.
          // We simply ignore it to avoid resetting the language by accident.
          if (code == null) return;

          // Looked up rather than captured from the loop, because the callback
          // now receives the VALUE, not the option.
          final option = LocaleController.options.firstWhere(
            (o) => (o.locale?.languageCode ?? 'system') == code,
          );
          
          await controller.setLocale(option.locale);
          if (mounted) setState(() {});
        },
        child: ListView(
          children: [
            for (final option in LocaleController.options)
              RadioListTile<String>(
                value: option.locale?.languageCode ?? 'system',
                // The one row that is NOT a language name. "System default" is
                // a sentence about the phone's setting, so it is translated
                // like any other; the entries beside it are endonyms and must
                // not be.
                title: Text(
                  option.locale == null
                      ? context.l10n.systemDefault
                      : option.label,
                  style: context.texts.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
