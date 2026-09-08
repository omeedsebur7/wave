import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/widgets/directional_chevron.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
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
    final s = context.spacing; // FIXED
    final u = user;

    if (u == null || u.isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.profile)),
        body: Padding(
          padding: EdgeInsetsDirectional.all(s.x32), // FIXED
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: s.x48, color: c.textSecondary), // FIXED
              SizedBox(height: s.x16), // FIXED
              Text(context.l10n.browsingAsGuest,
                  style: context.texts.title, 
                  textAlign: TextAlign.center,),
              SizedBox(height: s.x8), // FIXED
              Text(
                context.l10n.guestUpgradeBody,
                style: context.texts.caption, 
                textAlign: TextAlign.center,
              ),
              SizedBox(height: s.x20), // FIXED
              WaveButton( 
                expand: true,
                label: context.l10n.createAnAccount,
                onPressed: () => context.push(Routes.signIn),
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
            padding: EdgeInsetsDirectional.all(s.x20), // FIXED
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32, // FIXED
                  backgroundColor: c.border,
                  child: Text(
                    (u.displayName ?? '?')[0].toUpperCase(),
                    style: context.texts.headline, 
                  ),
                ),
                SizedBox(width: s.x16), // FIXED
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.displayName ?? context.l10n.you,
                          style: context.texts.title,), 
                      SizedBox(height: s.x4), // FIXED
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

          SizedBox(height: s.x40), // FIXED
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.preparingYourData)),
    );
    await getIt<DataExportService>()
        .exportAndShare(shareSubject: context.l10n.yourWaveData);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final s = context.spacing; // FIXED

    final confirmed = await WaveSheet.show<bool>(
      context: context,
      title: context.l10n.signOutQ,
      builder: (context) => Text(
        context.l10n.signOutBody,
        style: context.texts.body,
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WaveButton(
            variant: WaveButtonVariant.destructive,
            expand: true,
            label: context.l10n.signOut,
            onPressed: () => Navigator.pop(context, true),
          ),
          SizedBox(height: s.x8), // FIXED
          WaveButton(
            variant: WaveButtonVariant.tertiary,
            expand: true,
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (confirmed ?? false) bloc.add(const SignOutRequested());
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final s = context.spacing; // FIXED
    
    await WaveSheet.show<void>(
      context: context,
      title: context.l10n.deleteYourAccountQ,
      builder: (context) => Text(
        context.l10n.deleteAccountBody,
        style: context.texts.body,
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WaveButton(
            variant: WaveButtonVariant.destructive,
            expand: true,
            label: context.l10n.delete,
            onPressed: () => Navigator.pop(context), 
          ),
          SizedBox(height: s.x8), // FIXED
          WaveButton(
            variant: WaveButtonVariant.tertiary,
            expand: true,
            label: context.l10n.keepMyAccount,
            onPressed: () => Navigator.pop(context),
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
      title: Text(label, style: context.texts.body.copyWith(color: color)), 
      trailing: const DirectionalChevron(size: 20), // FIXED
      onTap: onTap,
    );
  }
}
