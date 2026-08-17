import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';

/// Picks one of YOUR OWN listings to attach to a Reel (§4, §5.1).
///
/// Only your own, and enforced server-side too — `publishReel` re-checks
/// ownership. Otherwise anyone could point a Buy Now button at someone else's
/// product and collect the attention for a sale they do not make.
Future<Product?> showProductLinkSheet(BuildContext context) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ProductLinkSheet(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.sellFromThisReel,
              style: context.texts.headlineMedium,),
          const SizedBox(height: 4),
          Text(
            context.l10n.sellFromThisReelBody,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 16),

          Flexible(
            child: FutureBuilder<List<Product>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final products = snapshot.data ?? const <Product>[];
                if (products.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.nothingListedYet,
                          style: context.texts.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push(Routes.listProduct);
                          },
                          child: Text(context.l10n.listAProductFirst),
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
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(WaveSurfaces.radiusChip),
                        child: CachedNetworkImage(
                          imageUrl: p.primaryImage,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: context.waveColors.border,
                          ),
                        ),
                      ),
                      title: Text(
                        p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodyMedium,
                      ),
                      subtitle: Text(
                        p.inStock
                            ? context.money(p.priceMinor, p.currency)
                            : context.l10n.outOfStock,
                        style: context.texts.bodySmall?.copyWith(
                          color: p.inStock
                              ? context.waveColors.textSecondary
                              : context.waveColors.error,
                        ),
                      ),
                      // Linking a sold-out product would put a Buy Now button
                      // on a Reel that cannot be bought from.
                      enabled: p.inStock,
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
