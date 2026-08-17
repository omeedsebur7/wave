import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/services/force_update_service.dart';
import 'package:wave/core/theme/app_theme.dart';

/// Force-update wall (§6).
///
/// No dismiss and no back. A build below the minimum supported version cannot
/// safely talk to the backend, so letting someone past this screen produces
/// confusing failures deeper in the app — an order that silently fails is worse
/// than a clear wall.
class ForceUpdatePage extends StatefulWidget {
  const ForceUpdatePage({super.key});

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage> {
  bool _launching = false;
  /// Whether the store link failed, not the words describing it.
  ///
  /// This was a `String?` holding an English sentence assigned in two places
  /// and rendered in a third. Nothing that inspects `Text(...)` arguments can
  /// catch that shape — the literal is nowhere near the widget — which is how it
  /// survived a localization pass that caught 250 others. Holding a bool and
  /// resolving the text in `build` makes it structurally impossible to repeat.
  bool _storeLinkFailed = false;

  Future<void> _openStore() async {
    setState(() {
      _launching = true;
      _storeLinkFailed = false;
    });

    // The URL comes from Remote Config, so a wrong store link can be corrected
    // without shipping a build — which matters when the build that needs
    // correcting is the one nobody can update past.
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
      // Never leave the button looking like it did nothing. If the store will
      // not open, say what to do by hand.
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
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.system_update, size: 56, color: c.primary),
                const SizedBox(height: 24),
                Text(
                  context.l10n.updateRequiredTitle,
                  style: context.texts.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.updateRequiredBody,
                  style: context.texts.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _launching ? null : _openStore,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 52),
                  ),
                  child: _launching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(context.l10n.updateNow),
                ),
                if (_storeLinkFailed) ...[
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.updateSearchStoreManually,
                    style: context.texts.bodySmall?.copyWith(color: c.warning),
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
