import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';

/// Shown to a suspended account.
///
/// Not a wall. A suspended user keeps read access on purpose: they can still see
/// their orders — a suspended seller may have deliveries outstanding, and
/// hiding those would strand the buyers waiting on them — and they can read the
/// policy they broke, which is the only route to an appeal that goes anywhere.
///
/// Writes are blocked by Security Rules, not by this screen. This exists so the
/// refusal is explained rather than appearing as a string of failed actions.
class SuspendedBanner extends StatelessWidget {
  const SuspendedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: c.error.withValues(alpha: 0.10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block, size: 18, color: c.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.accountSuspended,
                  style: context.texts.labelMedium?.copyWith(color: c.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.accountSuspendedBody,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push(Routes.legalPath('content-policy')),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
            ),
            child: Text(context.l10n.readContentPolicy),
          ),
        ],
      ),
    );
  }
}
