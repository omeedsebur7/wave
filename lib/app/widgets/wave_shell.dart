import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/widgets/offline_banner.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wave/features/moderation/presentation/pages/suspended_page.dart';
import 'package:wave/features/publish/presentation/widgets/publish_sheet.dart';

/// The 5-element navigation shell (§2): Reels, Marketplace, a docked FAB for
/// Publish, Chat, Profile.
///
/// The FAB is centre-docked in a BottomAppBar so the four tabs sit
/// symmetrically around it — two left, two right. The notch is what makes the
/// publish action feel like the app's centre of gravity rather than a fifth
/// equal tab.
///
/// Everything here is RTL-aware. The tab order reverses under an RTL locale
/// automatically because Row respects Directionality; the FAB stays centred,
/// which is correct in both directions.
class WaveShell extends StatelessWidget {
  const WaveShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _goBranch(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Scaffold(
      body: BlocSelector<AuthBloc, AuthState, bool>(
        selector: (state) => state.user?.isSuspended ?? false,
        builder: (context, suspended) {
          // Both banners sit above the tabs rather than over them. A modal wall
          // would be wrong for either: a suspended seller still needs to reach
          // outstanding orders, and an offline user can still browse cached
          // content and queue writes.
          return Column(
            children: [
              // Offline first — it is the more transient of the two, and it is
              // the one that changes what a tap means right now.
              const OfflineBanner(),
              if (suspended) const SuspendedBanner(),
              Expanded(child: shell),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () => showPublishSheet(context),
          backgroundColor: c.primary,
          // The FAB is one of the three places the accent glow is allowed
          // (§3.4) — it carries the floating elevation tier.
          elevation: 0,
          tooltip: context.l10n.publish,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 64,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.play_circle_outline,
              activeIcon: Icons.play_circle_fill,
              label: context.l10n.navReels,
              index: 0,
              currentIndex: shell.currentIndex,
              onTap: _goBranch,
            ),
            _NavItem(
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront,
              label: context.l10n.navMarketplace,
              index: 1,
              currentIndex: shell.currentIndex,
              onTap: _goBranch,
            ),
            const SizedBox(width: 56), // space reserved for the docked FAB
            _NavItem(
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: context.l10n.navChat,
              index: 2,
              currentIndex: shell.currentIndex,
              onTap: _goBranch,
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: context.l10n.navProfile,
              index: 3,
              currentIndex: shell.currentIndex,
              onTap: _goBranch,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final selected = index == currentIndex;
    final color = selected ? c.primary : c.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          // Minimum 48x48dp touch target (§3.5).
          constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 2),
              ExcludeSemantics(
                child: Text(
                  label,
                  style: context.texts.bodySmall?.copyWith(
                    color: color,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
