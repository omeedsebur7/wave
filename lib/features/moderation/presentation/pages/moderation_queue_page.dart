import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/moderation/data/moderation_repository.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';

/// The moderator review queue (§4).
///
/// Deliberately English-only. This is an internal tool for a small team, not a
/// user-facing surface, and translating it into three languages would be cost
/// with no reader. It is also not linked from anywhere a normal user can reach:
/// you arrive by URL, and the screen refuses unless your token carries the
/// moderator claim.
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data != true) {
            // Says nothing about the queue's contents or size. A refusal that
            // leaked "12 reports pending" would be a small intelligence gift to
            // someone probing.
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
                return const Center(child: CircularProgressIndicator());
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
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                        // No success toast. The item leaving the queue IS the
                        // confirmation, and a moderator working through a list
                        // does not want a toast per decision.
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: report.isUrgent ? c.error : c.border,
          width: report.isUrgent ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (report.isUrgent) ...[
                Icon(Icons.priority_high, size: 18, color: c.error),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  '${report.targetType.name} · ${report.reason.name}',
                  style: context.texts.labelMedium,
                ),
              ),
              if (report.reportCount > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  // The number that matters most: one report is an opinion,
                  // eight independent ones is a pattern.
                  child: Text(
                    '${report.reportCount} reports',
                    style: context.texts.bodySmall?.copyWith(color: c.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Selectable so a moderator can copy the id into the app or the
          // console to see the thing itself. There is deliberately no preview:
          // rendering reported content inline would mean a moderator sees every
          // piece of it whether or not they chose to.
          SelectableText(
            report.targetId,
            style: context.texts.bodySmall?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 12),

          // The reporter's identity is never rendered anywhere on this screen.
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
    final c = context.waveColors;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: destructive ? c.error : null),
      label: Text(label),
      onPressed: onTap,
      labelStyle: destructive
          ? context.texts.bodySmall?.copyWith(color: c.error)
          : context.texts.bodySmall,
    );
  }
}
