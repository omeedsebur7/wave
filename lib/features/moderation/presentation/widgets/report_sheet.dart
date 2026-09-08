import 'package:flutter/material.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/features/moderation/data/moderation_repository.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';

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

Future<void> showReportSheet(
  BuildContext context, {
  required ReportTargetType targetType,
  required String targetId,
}) {
  // FIXED: Replaced standard bottom sheet with WaveSheet
  return WaveSheet.show<void>(
    context: context,
    title: context.l10n.reportThis,
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
        padding: const EdgeInsetsDirectional.all(WaveSpacing.x32), // FIXED
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: WaveSpacing.x48, // FIXED
              color: context.waveColors.success,
            ),
            const SizedBox(height: WaveSpacing.x16), // FIXED
            Text(context.l10n.reportSent, style: context.texts.title), // FIXED
            const SizedBox(height: WaveSpacing.x8), // FIXED
            Text(
              context.l10n.reportSentBody,
              style: context.texts.caption, // FIXED
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WaveSpacing.x20), // FIXED
            WaveButton( // FIXED
              expand: true,
              label: context.l10n.done,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x32), // FIXED
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.whatIsWrongWithIt, style: context.texts.caption), // FIXED
          const SizedBox(height: WaveSpacing.x12), // FIXED

          Flexible(
            child: SingleChildScrollView(
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
                          style: context.texts.body, // FIXED
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
                style: context.texts.body, // FIXED
              ),
              subtitle: Text(
                context.l10n.blockExplainer,
                style: context.texts.caption, // FIXED
              ),
              contentPadding: EdgeInsets.zero,
            ),

          const SizedBox(height: WaveSpacing.x12), // FIXED
          SizedBox(
            width: double.infinity,
            child: WaveButton( // FIXED
              expand: true,
              isLoading: _submitting,
              label: context.l10n.sendReport,
              onPressed: _reason == null || _submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}
