import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/utils/money.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/selling/data/seller_stats_repository.dart';
import 'package:wave/features/selling/domain/entities/seller_stats.dart';

class SellerStatsPage extends StatefulWidget {
  const SellerStatsPage({super.key});

  @override
  State<SellerStatsPage> createState() => _SellerStatsPageState();
}

class _SellerStatsPageState extends State<SellerStatsPage> {
  late Future<SellerStats?> _future = _load();

  Future<SellerStats?> _load() async {
    final result = await getIt<SellerStatsRepository>().load();
    return result.valueOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.howYouAreDoing)),
      body: FutureBuilder<SellerStats?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // FIXED: Replaced standard CircularProgressIndicator with WaveStateView
            return const WaveStateView(
              state: WaveLoading(SizedBox.shrink()),
              content: SizedBox.shrink(),
            );
          }

          final s = snapshot.data;
          if (s == null) {
            return WaveErrorView(
              title: context.l10n.statsNotLoaded,
              message: context.l10n.errorNoConnectionBody,
              onRetry: () => setState(() => _future = _load()),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              padding: const EdgeInsetsDirectional.all(WaveSpacing.x20), // FIXED
              children: [
                if (s.ordersAwaitingAction > 0) _ActionBanner(stats: s),

                Text(context.l10n.lastNDays(s.periodDays),
                    style: context.texts.title,), // FIXED
                const SizedBox(height: WaveSpacing.x12), // FIXED

                Row(
                  children: [
                    _Stat(
                      value: context.money(s.revenueMinor, s.currency),
                      label: context.l10n.earned,
                    ),
                    _Stat(
                      value: context.number(s.ordersPlaced),
                      label: context.l10n.orders,
                    ),
                    _Stat(
                      value: s.ratingCount == 0
                          ? '—'
                          : context.decimal(s.avgRating),
                      label: context.l10n.rating,
                    ),
                  ],
                ),

                const SizedBox(height: WaveSpacing.x32), // FIXED
                Text(context.l10n.wherePeopleDropOff,
                    style: context.texts.title,), // FIXED
                const SizedBox(height: WaveSpacing.x4), // FIXED
                Text(
                  s.hasEnoughDataToJudge
                      ? context.l10n.funnelExplainer
                      : context.l10n.funnelLowSample,
                  style: context.texts.caption, // FIXED
                ),
                const SizedBox(height: WaveSpacing.x16), // FIXED

                _FunnelStep(
                  label: context.l10n.funnelWatched,
                  value: s.reelViews,
                  fraction: 1,
                ),
                _FunnelStep(
                  label: context.l10n.funnelTapped,
                  value: s.buyNowTaps,
                  fraction: s.tapThroughRate,
                  note: _tapThroughNote(context, s),
                ),
                _FunnelStep(
                  label: context.l10n.funnelCompleted,
                  value: s.ordersPlaced,
                  fraction: s.overallConversion,
                  note: _completionNote(context, s),
                ),

                const SizedBox(height: WaveSpacing.x32), // FIXED
                Text(context.l10n.yourReels, style: context.texts.title), // FIXED
                const SizedBox(height: WaveSpacing.x12), // FIXED

                if (s.topReels.isEmpty)
                  Text(
                    context.l10n.nothingPublishedYet,
                    style: context.texts.caption, // FIXED
                  )
                else
                  for (final reel in s.topReels)
                    _ReelRow(reel: reel, currency: s.currency),

                const SizedBox(height: WaveSpacing.x40), // FIXED
              ],
            ),
          );
        },
      ),
    );
  }

  static String? _tapThroughNote(BuildContext context, SellerStats s) {
    if (!s.hasEnoughDataToJudge || s.buyNowTaps == 0) return null;
    return s.tapThroughRate < 0.02 ? context.l10n.lowTapThroughNote : null;
  }

  static String? _completionNote(BuildContext context, SellerStats s) {
    if (s.buyNowTaps < 20) return null;
    return s.tapToOrderRate < 0.3 ? context.l10n.lowCompletionNote : null;
  }
}

class _ActionBanner extends StatelessWidget {
  const _ActionBanner({required this.stats});

  final SellerStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x24), // FIXED
      padding: const EdgeInsetsDirectional.all(WaveSpacing.x16), // FIXED
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
        border: Border.all(color: c.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: c.warning),
          const SizedBox(width: WaveSpacing.x12), // FIXED
          Expanded(
            child: Text(
              stats.ordersAwaitingAction == 1
                  ? context.l10n.ordersWaitingOne
                  : context.l10n.ordersWaitingMany(stats.ordersAwaitingAction),
              style: context.texts.label.copyWith(color: c.warning), // FIXED
            ),
          ),
          WaveButton( // FIXED: TextButton -> WaveButton
            variant: WaveButtonVariant.tertiary,
            size: WaveButtonSize.sm,
            label: context.l10n.open,
            onPressed: () => context.push(Routes.sellerOrders),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: context.l10n.statSemantic(value, label),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(value, style: context.texts.headline), // FIXED
              ),
              Text(label, style: context.texts.caption), // FIXED
            ],
          ),
        ),
      ),
    );
  }
}

class _FunnelStep extends StatelessWidget {
  const _FunnelStep({
    required this.label,
    required this.value,
    required this.fraction,
    this.note,
  });

  final String label;
  final int value;
  final double fraction;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x16), // FIXED
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.texts.body)), // FIXED
              Text(context.number(value), style: context.texts.label), // FIXED
              const SizedBox(width: WaveSpacing.x8), // FIXED
              SizedBox(
                width: WaveSpacing.x48, // FIXED
                child: Text(
                  context.percent(fraction, decimals: fraction < 0.1 ? 1 : 0),
                  textAlign: TextAlign.end,
                  style: context.texts.caption, // FIXED
                ),
              ),
            ],
          ),
          const SizedBox(height: WaveSpacing.x8), // FIXED
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: WaveSpacing.x8, // FIXED
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation(c.primary),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: WaveSpacing.x8), // FIXED
            Text(
              note!,
              style: context.texts.caption.copyWith(color: c.textSecondary), // FIXED
            ),
          ],
        ],
      ),
    );
  }
}

class _ReelRow extends StatelessWidget {
  const _ReelRow({required this.reel, required this.currency});

  final ReelPerformance reel;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x16), // FIXED
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
            child: CachedNetworkImage(
              imageUrl: reel.thumbnailUrl,
              width: WaveSpacing.x48, // FIXED
              height: WaveSpacing.x64, // FIXED
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(width: WaveSpacing.x48, height: WaveSpacing.x64, color: c.border),
            ),
          ),
          const SizedBox(width: WaveSpacing.x12), // FIXED
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reel.caption.isEmpty
                      ? context.l10n.untitledReel
                      : reel.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.body, // FIXED
                ),
                const SizedBox(height: 2), // FIXED
                Text(
                  context.l10n.viewsAndSold(reel.views, reel.orders),
                  style: context.texts.caption, // FIXED
                ),

                if (reel.isWastedAudience) ...[
                  const SizedBox(height: WaveSpacing.x8), // FIXED
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: WaveSpacing.x8,
                      vertical: WaveSpacing.x4,
                    ), // FIXED
                    decoration: BoxDecoration(
                      color: c.info.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(context.surfaces.radiusChip),
                    ),
                    child: Text(
                      context.l10n.wastedAudienceNote(reel.views),
                      style: context.texts.caption.copyWith(color: c.info), // FIXED
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
