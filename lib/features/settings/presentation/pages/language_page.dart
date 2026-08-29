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
      // Typed RadioGroup<String?> rather than <String>, because null is a
      // MEANINGFUL value here — it is "system default", the first option — not
      // merely "nothing selected". That overloading predates this migration
      // and is worth knowing about: RadioGroup also passes null to onChanged
      // when a selection is cleared, so the two cases are indistinguishable
      // from the callback alone. It is safe today only because nothing in this
      // screen can clear a selection; a future `toggleable: true` on any tile
      // here would silently start setting the locale to system-default on a
      // second tap of the active row.
      body: RadioGroup<String?>(
        groupValue: controller.locale?.languageCode,
        onChanged: (code) async {
          // Looked up rather than captured from the loop, because the callback
          // now receives the VALUE, not the option. firstWhere matches the
          // system-default entry when code is null, since that option's own
          // locale is null too.
          final option = LocaleController.options.firstWhere(
            (o) => o.locale?.languageCode == code,
          );
          await controller.setLocale(option.locale);
          if (mounted) setState(() {});
        },
        child: ListView(
          children: [
            for (final option in LocaleController.options)
              RadioListTile<String?>(
                value: option.locale?.languageCode,
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
