import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/moderation/data/moderation_repository.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';

class ModerationQueuePage extends StatefulWidget {
  const ModerationQueuePage({super.key});

  @override
  State<ModerationQueuePage> createState() => _ModerationQueuePageState();
}

class _ModerationQueuePageState extends State<ModerationQueuePage> {
  final _repo = getIt<ModerationRepository>();
  late final Future<bool> _access = _repo.isModerator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review queue')),
      body: FutureBuilder<bool>(
        future: _access,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // FIXED: Replaced standard CircularProgressIndicator with WaveStateView
            return const WaveStateView(
              state: WaveLoading(SizedBox.shrink()),
              content: SizedBox.shrink(),
            );
          }

          if (snapshot.data != true) {
            return WaveErrorView(
              title: 'Not available',
              message: 'This area is for moderators.',
              icon: Icons.lock_outline,
              retryLabel: 'Go back',
              onRetry: () => context.go(Routes.reels),
            );
          }

          return StreamBuilder<List<Report>>(
            stream: _repo.watchQueue(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const WaveStateView(
                  state: WaveLoading(SizedBox.shrink()),
                  content: SizedBox.shrink(),
                );
              }

              final reports = snap.data ?? const <Report>[];
              if (reports.isEmpty) {
                return const WaveErrorView.empty(
                  title: 'Queue is clear',
                  message: 'Nothing is waiting for review.',
                  icon: Icons.done_all,
                );
              }

              return ListView.separated(
                padding: const EdgeInsetsDirectional.all(WaveSpacing.x16), // FIXED
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: WaveSpacing.x12), // FIXED
                itemBuilder: (context, i) {
                  final report = reports[i];
                  return _ReportCard(
                    report: report,
                    onResolve: (action) async {
                      final result = await _repo.resolve(
                        reportId: report.id,
                        action: action,
                      );
                      if (!context.mounted) return;
                      result.fold(
                        (f) => ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(f.message))),
                        (_) {},
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onResolve});

  final Report report;
  final Future<void> Function(ModerationAction) onResolve;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Container(
      padding: const EdgeInsetsDirectional.all(WaveSpacing.x16), // FIXED
      decoration: BoxDecoration(
        border: Border.all(
          color: report.isUrgent ? c.error : c.border,
          width: report.isUrgent ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (report.isUrgent) ...[
                Icon(Icons.priority_high, size: WaveSpacing.x16, color: c.error), // FIXED
                const SizedBox(width: WaveSpacing.x8), // FIXED
              ],
              Expanded(
                child: Text(
                  '${report.targetType.name} · ${report.reason.name}',
                  style: context.texts.label, // FIXED
                ),
              ),
              if (report.reportCount > 1)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: WaveSpacing.x8, 
                    vertical: 2,
                  ), // FIXED
                  decoration: BoxDecoration(
                    color: c.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(WaveSpacing.x8),
                  ),
                  child: Text(
                    '${report.reportCount} reports',
                    style: context.texts.caption.copyWith(color: c.warning), // FIXED
                  ),
                ),
            ],
          ),
          const SizedBox(height: WaveSpacing.x8), // FIXED

          SelectableText(
            report.targetId,
            style: context.texts.caption.copyWith(color: c.textSecondary), // FIXED
          ),
          const SizedBox(height: WaveSpacing.x12), // FIXED

          Wrap(
            spacing: WaveSpacing.x8,
            runSpacing: WaveSpacing.x8,
            children: [
              _ActionChip(
                label: 'Dismiss',
                icon: Icons.close,
                onTap: () => onResolve(ModerationAction.dismissed),
              ),
              _ActionChip(
                label: 'Remove content',
                icon: Icons.delete_outline,
                destructive: true,
                onTap: () => onResolve(ModerationAction.contentRemoved),
              ),
              _ActionChip(
                label: 'Warn account',
                icon: Icons.warning_amber_outlined,
                onTap: () => onResolve(ModerationAction.accountWarned),
              ),
              _ActionChip(
                label: 'Suspend account',
                icon: Icons.block,
                destructive: true,
                onTap: () => onResolve(ModerationAction.accountSuspended),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    // FIXED: Replaced standard ActionChip with proper WaveButton sizes
    return WaveButton(
      variant: destructive ? WaveButtonVariant.destructive : WaveButtonVariant.secondary,
      size: WaveButtonSize.sm,
      icon: icon,
      label: label,
      onPressed: onTap,
    );
  }
}
