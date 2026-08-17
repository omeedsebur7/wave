import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/core/widgets/wave_skeleton.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';
import 'package:wave/features/marketplace/presentation/widgets/product_card.dart';

/// Saved products.
///
/// Deliberately shows sold-out favourites rather than hiding them: a saved item
/// that quietly vanishes reads as a bug, and knowing something sold out is
/// itself useful — it tells you to move faster next time.
class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  late Future<List<Product>> _future = _load();

  Future<List<Product>> _load() async {
    final repo = getIt<ProductRepository>();
    final ids = await repo.favouriteIds();
    final favouriteIds = ids.valueOrNull ?? <String>{};
    if (favouriteIds.isEmpty) return [];

    // Parallel point reads. A whereIn query caps at 30 ids and would need
    // chunking anyway, and these are cheap cached reads on a revisit.
    final results = await Future.wait(favouriteIds.map(repo.byId));
    return [
      for (final r in results)
        if (r.valueOrNull != null) r.valueOrNull!,
    ];
  }

  Future<void> _unfavourite(String productId) async {
    await getIt<ProductRepository>().toggleFavourite(productId, saved: false);
    if (mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.favourites)),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: _grid,
              itemCount: 4,
              itemBuilder: (_, __) => const ProductCardSkeleton(),
            );
          }

          final products = snapshot.data ?? const <Product>[];
          if (products.isEmpty) {
            return WaveErrorView.empty(
              title: context.l10n.nothingSavedYet,
              message: context.l10n.favouritesBody,
              icon: Icons.favorite_border,
              retryLabel: context.l10n.browseTheMarket,
              onRetry: () => context.go(Routes.marketplace),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: _grid,
            itemCount: products.length,
            itemBuilder: (context, i) => ProductCard(
              product: products[i],
              isFavourite: true,
              onTap: () => context.push(
                Routes.productDetailPath(products[i].id),
                extra: products[i],
              ),
              onFavouriteToggle: () => _unfavourite(products[i].id),
            ),
          );
        },
      ),
    );
  }

  static const _grid = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 16,
    childAspectRatio: 0.62,
  );
}
