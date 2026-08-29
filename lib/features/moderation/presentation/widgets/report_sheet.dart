import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/features/moderation/data/moderation_repository.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';

/// Labels live in the ARB, not on the enum — an enum constant cannot reach a
/// BuildContext, so a label carried there would be guaranteed never to
/// translate.
String _reasonLabel(BuildContext context, ReportReason reason) =>
    switch (reason) {
      ReportReason.spam => context.l10n.reasonSpam,
      ReportReason.counterfeit => context.l10n.reasonCounterfeit,
      ReportReason.prohibited => context.l10n.reasonProhibited,
      ReportReason.harassment => context.l10n.reasonHarassment,
      ReportReason.sexual => context.l10n.reasonSexual,
      ReportReason.violence => context.l10n.reasonViolence,
      ReportReason.intellectualProperty =>
        context.l10n.reasonIntellectualProperty,
      ReportReason.other => context.l10n.reasonOther,
    };

/// Report flow (§4). Launch-blocking, not a later trust & safety pass — a
/// marketplace without a report button is one bad listing away from a problem
/// it has no way to hear about.
///
/// Reports are write-only from the client (see firestore.rules): anyone can
/// file one, only a moderator can read the queue. If reports were readable by
/// the reported, a bad actor could check whether they'd been noticed and adapt.
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTargetType targetType,
  required String targetId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReportSheet(targetType: targetType, targetId: targetId),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.targetType, required this.targetId});
  final ReportTargetType targetType;
  final String targetId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  bool _alsoBlock = false;
  bool _submitted = false;
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final result = await getIt<ModerationRepository>().fileReport(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: _reason!,
      alsoBlock: _alsoBlock,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureText(context, f)))),
      (_) {
        // Reported volume by reason tells trust & safety which policy is being
        // tested, long before a human notices a pattern in the queue itself.
        getIt<AnalyticsService>().log(
          AnalyticsEvents.contentReported,
          params: {
            'target_type': widget.targetType.name,
            'reason': _reason!.name,
          },
        );
        setState(() => _submitted = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: context.waveColors.success,
            ),
            const SizedBox(height: 16),
            Text(context.l10n.reportSent, style: context.texts.titleMedium),
            const SizedBox(height: 8),
            // No promise about outcome or timing — an unkeepable promise here
            // is worse than none.
            Text(
              context.l10n.reportSentBody,
              style: context.texts.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.done),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.reportThis, style: context.texts.headlineMedium),
          const SizedBox(height: 4),
          Text(context.l10n.whatIsWrongWithIt, style: context.texts.bodySmall),
          const SizedBox(height: 12),

          Flexible(
            child: SingleChildScrollView(
              // RadioGroup replaces the per-tile groupValue/onChanged pair
              // deprecated after Flutter 3.32. The selection state and the
              // callback move up here; each tile below now declares only its
              // own value.
              child: RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (final reason in ReportReason.values)
                      RadioListTile<ReportReason>(
                        value: reason,
                        title: Text(
                          _reasonLabel(context, reason),
                          style: context.texts.bodyMedium,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (widget.targetType != ReportTargetType.product)
            CheckboxListTile(
              value: _alsoBlock,
              onChanged: (v) => setState(() => _alsoBlock = v ?? false),
              title: Text(
                context.l10n.alsoBlockAccount,
                style: context.texts.bodyMedium,
              ),
              subtitle: Text(
                context.l10n.blockExplainer,
                style: context.texts.bodySmall,
              ),
              contentPadding: EdgeInsets.zero,
            ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _reason == null || _submitting ? null : _submit,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
              child: Text(context.l10n.sendReport),
            ),
          ),
        ],
      ),
    );
  }
}
