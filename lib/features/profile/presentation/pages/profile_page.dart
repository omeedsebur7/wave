import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/widgets/directional_chevron.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/features/auth/domain/entities/wave_user.dart';
import 'package:wave/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wave/features/legal/data/data_export_service.dart';
import 'package:wave/features/trust/domain/entities/trust_tier.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({this.user, this.tier = TrustTier.newSeller, super.key});

  final WaveUser? user;
  final TrustTier tier;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final u = user;

    // A guest sees a real screen with a reason to sign up, not an empty
    // profile shell. This is the highest-intent conversion point in the app.
    if (u == null || u.isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.profile)),
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 48, color: c.textSecondary),
              const SizedBox(height: 16),
              Text(context.l10n.browsingAsGuest,
                  style: context.texts.titleMedium,
                  textAlign: TextAlign.center,),
              const SizedBox(height: 8),
              Text(
                context.l10n.guestUpgradeBody,
                style: context.texts.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.push(Routes.signIn),
                child: Text(context.l10n.createAnAccount),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.l10n.settings,
            onPressed: () => context.push(Routes.notificationPrefs),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: c.border,
                  child: Text(
                    (u.displayName ?? '?')[0].toUpperCase(),
                    style: context.texts.headlineMedium,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.displayName ?? context.l10n.you,
                          style: context.texts.titleMedium,),
                      const SizedBox(height: 6),
                      if (tier.hasBadge) TrustBadge(tier: tier),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          _Row(
            icon: Icons.receipt_long_outlined,
            label: context.l10n.yourOrders,
            onTap: () => context.push(Routes.orders),
          ),
          _Row(
            icon: Icons.storefront_outlined,
            label: context.l10n.ordersToFulfil,
            onTap: () => context.push(Routes.sellerOrders),
          ),
          _Row(
            icon: Icons.insights_outlined,
            label: context.l10n.howYouAreDoing,
            onTap: () => context.push(Routes.sellerStats),
          ),
          _Row(
            icon: Icons.favorite_border,
            label: context.l10n.favourites,
            onTap: () => context.push(Routes.favourites),
          ),
          _Row(
            icon: Icons.bookmark_border,
            label: context.l10n.savedReels,
            onTap: () => context.push(Routes.savedReels),
          ),
          _Row(
            icon: Icons.notifications_outlined,
            label: context.l10n.notifications,
            onTap: () => context.push(Routes.notificationPrefs),
          ),
          _Row(
            icon: Icons.language,
            // In all three scripts, so it is findable by someone currently
            // reading the app in a language they did not choose.
            label: 'Language · اللغة · زمان',
            onTap: () => context.push(Routes.language),
          ),

          const Divider(),

          _Row(
            icon: Icons.description_outlined,
            label: context.l10n.termsAndPolicies,
            onTap: () => context.push('/legal/terms'),
          ),
          _Row(
            icon: Icons.download_outlined,
            label: context.l10n.downloadYourData,
            onTap: () => _exportData(context),
          ),
          // Account deletion is offered plainly, not buried. It's a legal
          // requirement (§7) and hiding it just generates support tickets.
          _Row(
            icon: Icons.logout,
            label: context.l10n.signOut,
            onTap: () => _confirmSignOut(context),
          ),
          _Row(
            icon: Icons.delete_outline,
            label: context.l10n.deleteYourAccount,
            destructive: true,
            onTap: () => _confirmDelete(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.preparingYourData)),
    );
    // Calls exportMyData and hands the JSON to the platform share sheet, so it
    // can go wherever the person actually wants it.
    await getIt<DataExportService>()
        .exportAndShare(shareSubject: context.l10n.yourWaveData);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AuthBloc>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.signOutQ),
        // Named explicitly because a shared phone is common, and someone
        // signing out wants to know the next person will not see their orders.
        content: Text(context.l10n.signOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed ?? false) bloc.add(const SignOutRequested());
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteYourAccountQ),
        content: SingleChildScrollView(
          // Says exactly what survives, because a promise of total erasure we
          // cannot keep is worse than an honest partial one. The Cloud Function
          // behind this does precisely what this copy describes.
          child: Text(context.l10n.deleteAccountBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.keepMyAccount),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: context.waveColors.error,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? context.waveColors.error : context.waveColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: context.texts.bodyMedium?.copyWith(color: color)),
      trailing: const DirectionalChevron(size: 20),
      onTap: onTap,
    );
  }
}
