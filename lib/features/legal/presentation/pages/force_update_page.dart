import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/services/force_update_service.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/design_system/components/wave_button.dart';

class ForceUpdatePage extends StatefulWidget {
  const ForceUpdatePage({super.key});

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage> {
  bool _launching = false;
  bool _storeLinkFailed = false;

  Future<void> _openStore() async {
    setState(() {
      _launching = true;
      _storeLinkFailed = false;
    });

    final isIos = !kIsWeb && Platform.isIOS;
    final url = getIt<ForceUpdateService>().updateUrl(isIos: isIos);

    if (url.isEmpty) {
      setState(() {
        _launching = false;
        _storeLinkFailed = true;
      });
      return;
    }

    final uri = Uri.tryParse(url);
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;
    setState(() {
      _launching = false;
      if (!opened) _storeLinkFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(WaveSpacing.x32), // FIXED
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.system_update, size: WaveSpacing.x64, color: c.primary), // FIXED
                const SizedBox(height: WaveSpacing.x24), // FIXED
                Text(
                  context.l10n.updateRequiredTitle,
                  style: context.texts.headline, // FIXED
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WaveSpacing.x8), // FIXED
                Text(
                  context.l10n.updateRequiredBody,
                  style: context.texts.caption, // FIXED
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WaveSpacing.x24), // FIXED
                SizedBox(
                  width: 200,
                  child: WaveButton( // FIXED: FilledButton -> WaveButton
                    expand: true,
                    isLoading: _launching,
                    label: context.l10n.updateNow,
                    onPressed: _launching ? null : _openStore,
                  ),
                ),
                if (_storeLinkFailed) ...[
                  const SizedBox(height: WaveSpacing.x12), // FIXED
                  Text(
                    context.l10n.updateSearchStoreManually,
                    style: context.texts.caption.copyWith(color: c.warning), // FIXED
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
