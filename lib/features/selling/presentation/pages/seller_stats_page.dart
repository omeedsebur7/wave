import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/selling/data/seller_stats_repository.dart';
import 'package:wave/features/selling/domain/entities/seller_stats.dart';

/// Seller analytics.
///
/// The layout follows one rule: a number that is also a task comes first, then
/// the funnel, then the individual Reels. A seller opening this screen is
/// asking "is it working, and what should I do?" — not "show me everything you
/// measured".
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
            return const Center(child: CircularProgressIndicator());
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
              padding: const EdgeInsets.all(20),
              children: [
                if (s.ordersAwaitingAction > 0) _ActionBanner(stats: s),

                Text(context.l10n.lastNDays(s.periodDays),
                    style: context.texts.titleMedium,),
                const SizedBox(height: 12),

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
                      // An em dash for "no ratings yet" is punctuation, not a
                      // word, so it needs no translation. The average does:
                      // toStringAsFixed always writes a Western decimal point.
                      value: s.ratingCount == 0
                          ? '—'
                          : context.decimal(s.avgRating),
                      label: context.l10n.rating,
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                Text(context.l10n.wherePeopleDropOff,
                    style: context.texts.titleMedium,),
                const SizedBox(height: 4),
                Text(
                  s.hasEnoughDataToJudge
                      ? context.l10n.funnelExplainer
                      : context.l10n.funnelLowSample,
                  style: context.texts.bodySmall,
                ),
                const SizedBox(height: 16),

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

                const SizedBox(height: 32),
                Text(context.l10n.yourReels, style: context.texts.titleMedium),
                const SizedBox(height: 12),

                if (s.topReels.isEmpty)
                  Text(
                    context.l10n.nothingPublishedYet,
                    style: context.texts.bodySmall,
                  )
                else
                  for (final reel in s.topReels)
                    _ReelRow(reel: reel, currency: s.currency),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The two halves of the funnel fail for opposite reasons and need opposite
  /// fixes, so the note names which one is happening rather than just
  /// reporting a percentage.
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
        border: Border.all(color: c.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: c.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stats.ordersAwaitingAction == 1
                  ? context.l10n.ordersWaitingOne
                  : context.l10n.ordersWaitingMany(stats.ordersAwaitingAction),
              style: context.texts.labelMedium?.copyWith(color: c.warning),
            ),
          ),
          TextButton(
            onPressed: () => context.push(Routes.sellerOrders),
            child: Text(context.l10n.open),
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
                child: Text(value, style: context.texts.headlineMedium),
              ),
              Text(label, style: context.texts.bodySmall),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: context.texts.bodyMedium)),
              Text(context.number(value), style: context.texts.labelMedium),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: Text(
                  context.percent(fraction, decimals: fraction < 0.1 ? 1 : 0),
                  textAlign: TextAlign.end,
                  style: context.texts.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 8,
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation(c.primary),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: context.texts.bodySmall?.copyWith(color: c.textSecondary),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
            child: CachedNetworkImage(
              imageUrl: reel.thumbnailUrl,
              width: 48,
              height: 64,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(width: 48, height: 64, color: c.border),
            ),
          ),
          const SizedBox(width: 12),
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
                  style: context.texts.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.viewsAndSold(reel.views, reel.orders),
                  style: context.texts.bodySmall,
                ),

                // The most actionable finding on the screen: an audience that
                // already exists, with nothing for them to buy. One tap fixes it.
                if (reel.isWastedAudience) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.info.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(WaveSurfaces.radiusChip),
                    ),
                    child: Text(
                      context.l10n.wastedAudienceNote(reel.views),
                      style: context.texts.bodySmall?.copyWith(color: c.info),
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
