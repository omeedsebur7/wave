import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart'; 
import 'package:wave/core/error/failure_to_state.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/design_system/components/wave_product_card.dart';
import 'package:wave/design_system/components/wave_skeletons.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/domain/repositories/product_repository.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  late Future<List<Product>> _future = _load();

  List<Product>? _products;

  static const _batchSize = 12;

  Future<List<Product>> _load() async {
    final repo = getIt<ProductRepository>();
    final ids = await repo.favouriteIds();

    final favouriteIds = ids.fold(
      (f) => throw _FavouritesFailure(f),
      (value) => value,
    );
    if (favouriteIds.isEmpty) return [];

    final products = <Product>[];
    final list = favouriteIds.toList();
    for (var start = 0; start < list.length; start += _batchSize) {
      final batch = list.skip(start).take(_batchSize);
      final results = await Future.wait(batch.map(repo.byId));
      for (final r in results) {
        final p = r.valueOrNull;
        if (p != null) products.add(p);
      }
    }
    return products;
  }

  Future<void> _unfavourite(String productId) async {
    final previous = _products;
    setState(() {
      _products = [
        for (final p in _products ?? const <Product>[])
          if (p.id != productId) p,
      ];
    });

    final result =
        await getIt<ProductRepository>().toggleFavourite(productId, saved: false);
    if (!mounted) return;

    result.fold(
      (f) {
        setState(() => _products = previous);
        if (isSignInPrompt(f.reason)) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failureText(context, f))));
      },
      (_) {},
    );
  }

  void _retry() => setState(() {
        _products = null;
        _future = _load();
      });

  SliverGridDelegate _grid(BuildContext context) {
    final s = context.spacing;
    final width = (MediaQuery.sizeOf(context).width - s.x16 * 2 - s.x12) / 2;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: s.x12,
      mainAxisSpacing: s.x16,
      mainAxisExtent: WaveProductCard.heightFor(context, width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.favourites)),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: EdgeInsetsDirectional.all(s.x16),
              gridDelegate: _grid(context),
              itemCount: 4,
              itemBuilder: (context, __) => WaveSkeletons.productCard(context),
            );
          }

          final error = snapshot.error;
          if (error != null) {
            final f = error is _FavouritesFailure ? error.failure : null;
            final kind =
                f == null ? WaveFailureKind.serverError : waveFailureKind(f);
            return WaveStateView(
              state: WaveFailure(
                kind,
                detail: f == null ? null : failureText(context, f),
                onRetry: isRetryable(kind) ? _retry : null,
              ),
              content: const SizedBox.shrink(),
            );
          }

          final products = _products ??= snapshot.data ?? const <Product>[];
          if (products.isEmpty) {
            return WaveStateView(
              state: WaveEmpty(
                icon: Icons.favorite_border,
                title: context.l10n.nothingSavedYet,
                body: context.l10n.favouritesBody,
                actionLabel: context.l10n.browseTheMarket,
                onAction: () => context.go(Routes.marketplace),
              ),
              content: const SizedBox.shrink(),
            );
          }

          return GridView.builder(
            padding: EdgeInsetsDirectional.all(s.x16),
            gridDelegate: _grid(context),
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              return WaveProductCard(
                productId: p.id,
                imageUrl: p.primaryImage,
                title: p.title,
                priceMinor: p.priceMinor,
                // FIXED: Removed `heroScope: 'favourites'` to allow standard hero flight to PDP!
                isFavourite: true,
                onFavouriteToggle: () => _unfavourite(p.id),
                onTap: () =>
                    context.push(Routes.productDetailPath(p.id), extra: p),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavouritesFailure implements Exception {
  const _FavouritesFailure(this.failure);
  final Failure failure;
}
