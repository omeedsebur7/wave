import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/error/failure_to_state.dart'; 
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/utils/dates.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/utils/numbers.dart';
import 'package:wave/core/widgets/trust_badge.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_sign_in_sheet.dart'; 
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';
import 'package:wave/features/moderation/domain/entities/report.dart';
import 'package:wave/features/moderation/presentation/widgets/report_sheet.dart';
import 'package:wave/features/profile/data/repositories/seller_profile_repository.dart';
import 'package:wave/features/profile/domain/entities/seller_profile.dart';

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
      (f) {
        if (isSignInPrompt(f.reason)) {
          WaveSignInSheet.show(
            context: context,
            onSuccess: () => _toggleFollow(profile),
          );
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failureText(context, f))));
      },
      (_) => setState(() => _future = _load()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing; // FIXED

    return Scaffold(
      body: FutureBuilder<(SellerProfile?, List<Product>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WaveStateView(
              state: WaveLoading(SizedBox.shrink()),
              content: SizedBox.shrink(),
            );
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
                padding: EdgeInsetsDirectional.all(s.x20), // FIXED
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36, // FIXED
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
                                  style: context.texts.headline, 
                                ),
                        ),
                        SizedBox(width: s.x16), // FIXED
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TrustBadge(
                                tier: profile.tier,
                                isKycVerified: profile.kycVerified,
                              ),
                              SizedBox(height: s.x8), // FIXED
                              Text(
                                context.l10n.sellingSince(
                                  _monthYear(context, profile.joinedAt),
                                ),
                                style: context.texts.caption, 
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      SizedBox(height: s.x16), // FIXED
                      Text(profile.bio!, style: context.texts.body), 
                    ],

                    SizedBox(height: s.x20), // FIXED
                    _TrackRecord(profile: profile),

                    SizedBox(height: s.x20), // FIXED
                    Row(
                      children: [
                        Expanded(
                          child: WaveButton( 
                            variant: WaveButtonVariant.secondary,
                            expand: true,
                            label: profile.isFollowedByMe
                                  ? context.l10n.following
                                  : context.l10n.follow,
                            onPressed: () => _toggleFollow(profile),
                          ),
                        ),
                        SizedBox(width: s.x12), // FIXED
                        Expanded(
                          child: WaveButton( 
                            variant: WaveButtonVariant.tertiary,
                            expand: true,
                            label: context.l10n.message,
                            onPressed: () => context.go(Routes.chat),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: s.x32), // FIXED
                    Text(
                      products.isEmpty
                          ? context.l10n.listings
                          : context.l10n.listingsCount(products.length),
                      style: context.texts.title, 
                    ),
                    SizedBox(height: s.x12), // FIXED
                  ],
                ),
              ),

              if (products.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: s.x20), // FIXED
                    child: Text(
                      context.l10n.nothingListedRightNow,
                      style: context.texts.caption, 
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      s.x20, 0, s.x20, s.x40,), // FIXED
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12, // FIXED
                      mainAxisSpacing: 16, // FIXED
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

class _TrackRecord extends StatelessWidget {
  const _TrackRecord({required this.profile});

  final SellerProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing; // FIXED

    if (!profile.hasTrackRecord) {
      return Container(
        padding: EdgeInsetsDirectional.all(s.x16), // FIXED
        decoration: BoxDecoration(
          color: c.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
          border: Border.all(color: c.info.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: c.info), // FIXED
            SizedBox(width: s.x12), // FIXED
            Expanded(
              child: Text(
                context.l10n.noTrackRecordBody,
                style: context.texts.caption.copyWith(color: c.info), 
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsetsDirectional.symmetric(vertical: s.x16), // FIXED
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
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
              Text(value, style: context.texts.headline), 
              Text(label, style: context.texts.caption), 
              if (sublabel.isNotEmpty)
                Text(
                  sublabel,
                  style: context.texts.caption.copyWith(fontSize: 11), // FIXED
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
      Container(width: 1, height: 40, color: color); // FIXED
}

class _MiniProductCard extends StatelessWidget {
  const _MiniProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing; // FIXED

    return InkWell(
      onTap: () => context.push(
        Routes.productDetailPath(product.id),
        extra: product,
      ),
      borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
              child: CachedNetworkImage(
                imageUrl: product.primaryImage,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => ColoredBox(color: c.border),
              ),
            ),
          ),
          SizedBox(height: s.x8), // FIXED
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.caption, 
          ),
          Text(
            context.money(product.priceMinor, product.currency),
            style: context.texts.label, 
          ),
        ],
      ),
    );
  }
}
