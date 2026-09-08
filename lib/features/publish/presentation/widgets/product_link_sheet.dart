import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';

/// Picks one of YOUR OWN listings to attach to a Reel (§4, §5.1).
Future<Product?> showProductLinkSheet(BuildContext context) {
  // FIXED: Replaced standard showModalBottomSheet with our signature WaveSheet physics!
  return WaveSheet.show<Product>(
    context: context,
    title: context.l10n.sellFromThisReel,
    builder: (context) => const _ProductLinkSheet(),
  );
}

class _ProductLinkSheet extends StatefulWidget {
  const _ProductLinkSheet();

  @override
  State<_ProductLinkSheet> createState() => _ProductLinkSheetState();
}

class _ProductLinkSheetState extends State<_ProductLinkSheet> {
  late final Future<List<Product>> _future = _load();

  Future<List<Product>> _load() async {
    final uid = getIt<FirebaseAuth>().currentUser?.uid;
    if (uid == null) return [];
    final result = await getIt<ProductRepository>().bySeller(uid);
    return result.valueOrNull ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.sellFromThisReelBody,
          style: context.texts.caption, // FIXED
        ),
        const SizedBox(height: WaveSpacing.x16),

        Flexible(
          child: FutureBuilder<List<Product>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsetsDirectional.all(WaveSpacing.x32),
                  child: WaveStateView( // FIXED: Removed bare CircularProgressIndicator
                    state: WaveLoading(SizedBox.shrink()),
                    content: SizedBox.shrink(),
                  ),
                );
              }

              final products = snapshot.data ?? const <Product>[];
              if (products.isEmpty) {
                return Padding(
                  padding: const EdgeInsetsDirectional.symmetric(vertical: WaveSpacing.x24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.nothingListedYet,
                        style: context.texts.body, // FIXED
                      ),
                      const SizedBox(height: WaveSpacing.x12),
                      WaveButton( // FIXED: FilledButton.tonal to WaveButton
                        variant: WaveButtonVariant.secondary,
                        label: context.l10n.listAProductFirst,
                        onPressed: () {
                          Navigator.pop(context);
                          context.push(Routes.listProduct);
                        },
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final p = products[i];
                  return ListTile(
                    contentPadding: EdgeInsetsDirectional.zero, // FIXED
                    leading: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(context.surfaces.radiusChip),
                      child: CachedNetworkImage(
                        imageUrl: p.primaryImage,
                        width: WaveSpacing.x48,
                        height: WaveSpacing.x48,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: WaveSpacing.x48,
                          height: WaveSpacing.x48,
                          color: context.waveColors.border,
                        ),
                      ),
                    ),
                    title: Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.body, // FIXED
                    ),
                    subtitle: Text(
                      p.inStock
                          ? context.money(p.priceMinor, p.currency)
                          : context.l10n.outOfStock,
                      style: context.texts.caption.copyWith( // FIXED
                        color: p.inStock
                            ? context.waveColors.textSecondary
                            : context.waveColors.error,
                      ),
                    ),
                    enabled: p.inStock,
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
