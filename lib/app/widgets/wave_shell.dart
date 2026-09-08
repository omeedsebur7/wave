import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/widgets/offline_banner.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wave/features/moderation/presentation/pages/suspended_page.dart';
import 'package:wave/features/publish/presentation/widgets/publish_sheet.dart';

class WaveShell extends StatelessWidget {
  const WaveShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _goBranch(int index) {
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

    return Scaffold(
      body: BlocSelector<AuthBloc, AuthState, bool>(
        selector: (state) => state.user?.isSuspended ?? false,
        builder: (context, suspended) {
          return Column(
            children: [
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
          elevation: 0,
          tooltip: context.l10n.publish,
          child: Icon(Icons.add, size: s.x24),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: s.x8,
        height: s.x64,
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
            SizedBox(width: s.x64), // space for FAB
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
    final s = context.spacing;
    final selected = index == currentIndex;
    final color = selected ? c.primary : c.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(s.x12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: s.x64, minHeight: s.x48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, color: color, size: s.x24),
              SizedBox(height: s.x4),
              ExcludeSemantics(
                child: Text(
                  label,
                  style: context.texts.caption.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
