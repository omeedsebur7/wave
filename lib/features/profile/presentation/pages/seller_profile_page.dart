import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/dates.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';
import 'package:wave/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:wave/features/profile/data/repositories/seller_profile_repository.dart';
import 'package:wave/features/profile/domain/entities/seller_profile.dart';

/// A seller's public profile.
///
/// This screen is the payoff for the whole trust-tier system: it's where a
/// buyer decides whether to trust a stranger enough to send them money. So the
/// evidence leads — tier, rating, completed orders, time on the platform — and
/// the listings follow.
class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({required this.sellerId, super.key});

  final String sellerId;

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  late Future<(SellerProfile?, List<Product>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(SellerProfile?, List<Product>)> _load() async {
    final profileResult =
        await getIt<SellerProfileRepository>().byId(widget.sellerId);
    final productsResult =
        await getIt<ProductRepository>().bySeller(widget.sellerId);

    return (
      profileResult.valueOrNull,
      productsResult.valueOrNull ?? const <Product>[],
    );
  }

  Future<void> _toggleFollow(SellerProfile profile) async {
    final result = await getIt<SellerProfileRepository>().toggleFollow(
      profile.id,
      follow: !profile.isFollowedByMe,
    );
    if (!mounted) return;

    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureText(context, f)))),
      (_) => setState(() => _future = _load()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<(SellerProfile?, List<Product>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data?.$1;
          final products = snapshot.data?.$2 ?? const <Product>[];

          if (profile == null) {
            return WaveErrorView(
              title: context.l10n.sellerNotFound,
              message: context.l10n.sellerNotFoundBody,
              icon: Icons.person_off_outlined,
              retryLabel: context.l10n.backToTheMarket,
              onRetry: () => context.go(Routes.marketplace),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(
                  profile.displayName.isEmpty
                      ? context.l10n.seller
                      : profile.displayName,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.flag_outlined),
                    tooltip: context.l10n.reportOrBlock,
                    onPressed: () => showReportSheet(
                      context,
                      targetType: ReportTargetType.profile,
                      targetId: profile.id,
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: context.waveColors.border,
                          backgroundImage: profile.avatarUrl == null
                              ? null
                              : CachedNetworkImageProvider(profile.avatarUrl!),
                          child: profile.avatarUrl != null
                              ? null
                              : Text(
                                  profile.displayName.isEmpty
                                      ? '?'
                                      : profile.displayName[0].toUpperCase(),
                                  style: context.texts.headlineMedium,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TrustBadge(
                                tier: profile.tier,
                                isKycVerified: profile.kycVerified,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.sellingSince(
                                  _monthYear(context, profile.joinedAt),
                                ),
                                style: context.texts.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(profile.bio!, style: context.texts.bodyMedium),
                    ],

                    const SizedBox(height: 20),
                    _TrackRecord(profile: profile),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => _toggleFollow(profile),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            child: Text(
                              profile.isFollowedByMe
                                  ? context.l10n.following
                                  : context.l10n.follow,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go(Routes.chat),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            child: Text(context.l10n.message),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Text(
                      products.isEmpty
                          ? context.l10n.listings
                          : context.l10n.listingsCount(products.length),
                      style: context.texts.titleMedium,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              if (products.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      context.l10n.nothingListedRightNow,
                      style: context.texts.bodySmall,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) =>
                        _MiniProductCard(product: products[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _monthYear(BuildContext context, DateTime d) =>
      Dates.monthYear(context, d);
}

/// The evidence panel.
///
/// A new seller gets an honest, non-alarming line rather than a row of zeros.
/// Three zeros reads as "avoid this person"; "no completed orders yet" reads as
/// what it is, and lets the buyer make their own call.
class _TrackRecord extends StatelessWidget {
  const _TrackRecord({required this.profile});

  final SellerProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    if (!profile.hasTrackRecord) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
          border: Border.all(color: c.info.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: c.info),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.noTrackRecordBody,
                style: context.texts.bodySmall?.copyWith(color: c.info),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
      ),
      child: Row(
        children: [
          _Stat(
            value: context.decimal(profile.avgRating),
            label: context.l10n.rating,
            sublabel: context.l10n.ratingsCount(profile.ratingCount),
          ),
          _Divider(color: c.border),
          _Stat(
            value: '${profile.completedOrders}',
            label: context.l10n.orders,
            sublabel: context.l10n.delivered,
          ),
          _Divider(color: c.border),
          _Stat(
            value: '${profile.followerCount}',
            label: context.l10n.followers,
            sublabel: '',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.sublabel,
  });

  final String value;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: [
        context.l10n.statSemantic(value, label),
        if (sublabel.isNotEmpty) sublabel,
      ].join(', '),
        child: ExcludeSemantics(
          child: Column(
            children: [
              Text(value, style: context.texts.headlineMedium),
              Text(label, style: context.texts.bodySmall),
              if (sublabel.isNotEmpty)
                Text(
                  sublabel,
                  style: context.texts.bodySmall?.copyWith(fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: color);
}

class _MiniProductCard extends StatelessWidget {
  const _MiniProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return InkWell(
      onTap: () => context.push(
        Routes.productDetailPath(product.id),
        extra: product,
      ),
      borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
              child: CachedNetworkImage(
                imageUrl: product.primaryImage,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => ColoredBox(color: c.border),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.bodySmall,
          ),
          Text(
            context.money(product.priceMinor, product.currency),
            style: context.texts.labelMedium,
          ),
        ],
      ),
    );
  }
}
