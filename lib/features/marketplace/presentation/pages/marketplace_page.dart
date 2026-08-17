import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/core/widgets/wave_skeleton.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:wave/features/marketplace/presentation/product_sort_text.dart';
import 'package:wave/features/marketplace/presentation/widgets/product_card.dart';

/// Marketplace grid with Firestore-backed search and sort (§4).
class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MarketplaceBloc>()..add(const MarketplaceStarted()),
      child: const _MarketplaceView(),
    );
  }
}

class _MarketplaceView extends StatefulWidget {
  const _MarketplaceView();

  @override
  State<_MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<_MarketplaceView> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      // Load the next page 600px before the bottom, so the grid never shows a
      // spinner the user has to wait at.
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 600) {
        context.read<MarketplaceBloc>().add(const MarketplaceLoadMore());
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MarketplaceBloc, MarketplaceState>(
          builder: (context, state) {
            return CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => context
                          .read<MarketplaceBloc>()
                          .add(MarketplaceSearchChanged(v)),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchProducts,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: state.query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _search.clear();
                                  context
                                      .read<MarketplaceBloc>()
                                      .add(const MarketplaceSearchChanged(''));
                                },
                              ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ),

                if (!state.isSearching)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          for (final sort in ProductSort.values)
                            Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(end: 8),
                              child: ChoiceChip(
                                label: Text(productSortLabel(context, sort)),
                                selected: state.sort == sort,
                                onSelected: (_) => context
                                    .read<MarketplaceBloc>()
                                    .add(MarketplaceSortChanged(sort)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                ..._body(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, MarketplaceState state) {
    if (state.status == MarketplaceStatus.loading ||
        state.status == MarketplaceStatus.initial) {
      return [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid.builder(
            gridDelegate: _grid,
            itemCount: 6,
            itemBuilder: (_, __) => const ProductCardSkeleton(),
          ),
        ),
      ];
    }

    if (state.status == MarketplaceStatus.failure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: WaveErrorView(
            title: context.l10n.productsNotLoaded,
            message: context.l10n.errorNoConnectionBody,
            onRetry: () => context
                .read<MarketplaceBloc>()
                .add(const MarketplaceStarted()),
          ),
        ),
      ];
    }

    if (state.products.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: state.isSearching
              ? WaveErrorView.empty(
                  title: context.l10n.nothingMatched(state.query),
                  message: context.l10n.searchPrefixNoteProducts,
                  icon: Icons.search_off,
                  retryLabel: context.l10n.clearSearch,
                  onRetry: () {
                    _search.clear();
                    context
                        .read<MarketplaceBloc>()
                        .add(const MarketplaceSearchChanged(''));
                  },
                )
              : WaveErrorView.empty(
                  title: context.l10n.marketEmpty,
                  message: context.l10n.marketEmptyBody,
                ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverGrid.builder(
          gridDelegate: _grid,
          itemCount: state.products.length,
          itemBuilder: (context, i) {
            final p = state.products[i];
            return ProductCard(
              product: p,
              isFavourite: state.favouriteIds.contains(p.id),
              // Hand the loaded product across so detail paints instantly
              // instead of re-fetching what this screen already holds.
              onTap: () => context.push(
                Routes.productDetailPath(p.id),
                extra: p,
              ),
              onFavouriteToggle: () => context
                  .read<MarketplaceBloc>()
                  .add(MarketplaceFavouriteToggled(p.id)),
            );
          },
        ),
      ),
      if (state.status == MarketplaceStatus.loadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      // Clears the docked FAB and bottom bar.
      const SliverToBoxAdapter(child: SizedBox(height: 88)),
    ];
  }

  static const _grid = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 16,
    childAspectRatio: 0.62,
  );
}
