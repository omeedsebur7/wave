import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/core/utils/dates.dart';
import 'package:wave/core/widgets/directional_chevron.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/legal/data/legal_repository.dart';
import 'package:wave/features/legal/domain/legal_document.dart';
import 'package:wave/features/legal/presentation/legal_doc_text.dart';

class LegalDocumentPage extends StatefulWidget {
  const LegalDocumentPage({required this.docType, super.key});

  final LegalDocType docType;

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  late Future<LegalDocument?> _future = _load();

  Future<LegalDocument?> _load() async {
    final result = await getIt<LegalRepository>().load(widget.docType);
    return result.valueOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(legalDocTitle(context, widget.docType)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: context.l10n.copy,
            onPressed: () async {
              final doc = await _future;
              if (doc == null || !context.mounted) return;
              await Clipboard.setData(ClipboardData(text: doc.body));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.copied)),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<LegalDocument?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // FIXED: Replaced CircularProgressIndicator with WaveStateView
            return const WaveStateView(
              state: WaveLoading(SizedBox.shrink()),
              content: SizedBox.shrink(),
            );
          }

          final doc = snapshot.data;
          if (doc == null) {
            return WaveErrorView(
              title: context.l10n.documentNotLoaded,
              message: context.l10n.errorNoConnectionBody,
              onRetry: () => setState(() => _future = _load()),
            );
          }

          return ListView(
            padding: const EdgeInsetsDirectional.all(WaveSpacing.x20), // FIXED
            children: [
              Text(
                context.l10n.versionUpdated(
                  doc.version,
                  _formatDate(context, doc.updatedAt),
                ),
                style: context.texts.caption, // FIXED
              ),
              const SizedBox(height: WaveSpacing.x16), // FIXED
              SelectableText(doc.body, style: context.texts.body), // FIXED
              const SizedBox(height: WaveSpacing.x40), // FIXED
            ],
          );
        },
      ),
    );
  }

  static String _formatDate(BuildContext context, DateTime d) =>
      Dates.short(context, d);
}

class TermsReacceptanceGate extends StatefulWidget {
  const TermsReacceptanceGate({
    required this.state,
    required this.onAccepted,
    super.key,
  });

  final AcceptanceState state;
  final VoidCallback onAccepted;

  @override
  State<TermsReacceptanceGate> createState() => _TermsReacceptanceGateState();
}

class _TermsReacceptanceGateState extends State<TermsReacceptanceGate> {
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);

    final result = await getIt<LegalRepository>().accept({
      for (final type in widget.state.outstanding)
        type: widget.state.currentVersions[type]!,
    });

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureText(context, f)))),
      (_) => widget.onAccepted(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outstanding = widget.state.outstanding;
    final isFirst = widget.state.isFirstAcceptance;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(WaveSpacing.x24), // FIXED
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFirst
                      ? context.l10n.beforeYouStart
                      : outstanding.length == 1
                          ? context.l10n.documentChanged(
                              legalDocTitle(context, outstanding.first),
                            )
                          : context.l10n.termsChanged,
                  style: context.texts.headline, // FIXED
                ),
                const SizedBox(height: WaveSpacing.x12), // FIXED
                Text(
                  isFirst
                      ? context.l10n.acceptToUse
                      : context.l10n.readWhatChanged,
                  style: context.texts.body, // FIXED
                ),
                const SizedBox(height: WaveSpacing.x20), // FIXED

                for (final type in outstanding)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(
                      legalDocTitle(context, type),
                      style: context.texts.label, // FIXED
                    ),
                    subtitle: Text(
                      context.l10n.versionLabel(
                        widget.state.currentVersions[type]!,
                      ),
                      style: context.texts.caption, // FIXED
                    ),
                    trailing: const DirectionalChevron(size: 20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LegalDocumentPage(docType: type),
                      ),
                    ),
                  ),

                const SizedBox(height: WaveSpacing.x24), // FIXED
                SizedBox(
                  width: double.infinity,
                  child: WaveButton( // FIXED: FilledButton -> WaveButton
                    expand: true,
                    isLoading: _saving,
                    label: context.l10n.acceptAndContinue,
                    onPressed: _saving ? null : _accept,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
