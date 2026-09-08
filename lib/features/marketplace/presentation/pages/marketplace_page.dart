import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/error/failure_to_state.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/design_system/components/wave_product_card.dart';
import 'package:wave/design_system/components/wave_sign_in_sheet.dart';
import 'package:wave/design_system/components/wave_skeletons.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/marketplace/presentation/bloc/marketplace_bloc.dart';
import 'package:wave/features/marketplace/presentation/product_sort_text.dart';

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
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final bloc = context.read<MarketplaceBloc>();
    final state = bloc.state;
    if (!state.hasMore ||
        state.isSearching ||
        state.status == MarketplaceStatus.loadingMore) {
      return;
    }

    final trigger = MediaQuery.sizeOf(context).height;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - trigger) {
      bloc.add(const MarketplaceLoadMore());
    }
  }

  void _clearSearch() {
    _search.clear();
    context.read<MarketplaceBloc>().add(const MarketplaceSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<MarketplaceBloc, MarketplaceState>(
          listenWhen: (_, next) => next.actionFailure != null,
          listener: (context, state) {
            final af = state.actionFailure;
            if (af == null) return;

            if (isSignInPrompt(af.failure.reason)) {
              final bloc = context.read<MarketplaceBloc>();
              WaveSignInSheet.show(
                context: context,
                onSuccess: () =>
                    bloc.add(MarketplaceFavouriteToggled(af.productId)),
              );
              return;
            }

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(failureText(context, af.failure))),
              );
          },
          builder: (context, state) {
            return CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      s.x16,
                      s.x12,
                      s.x16,
                      s.x8,
                    ),
                    child: WaveTextField(
                      label: context.l10n.searchProducts,
                      controller: _search,
                      hint: context.l10n.searchProducts,
                      onChanged: (v) => context
                          .read<MarketplaceBloc>()
                          .add(MarketplaceSearchChanged(v)),
                      prefixIcon: Icons.search,
                      suffixIcon: state.query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: context.l10n.clearSearch,
                              onPressed: _clearSearch,
                            ),
                    ),
                  ),
                ),
                if (!state.isSearching)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: s.controlMd,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding:
                            EdgeInsetsDirectional.symmetric(horizontal: s.x16),
                        children: [
                          for (final sort in ProductSort.values)
                            Padding(
                              padding: EdgeInsetsDirectional.only(end: s.x8),
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

  List<Widget> _body(BuildContext context, MarketplaceState state) {
    final s = context.spacing;

    if (state.status == MarketplaceStatus.loading ||
        state.status == MarketplaceStatus.initial) {
      return [
        SliverPadding(
          padding: EdgeInsetsDirectional.all(s.x16),
          sliver: SliverGrid.builder(
            gridDelegate: _grid(context),
            itemCount: 6,
            itemBuilder: (context, __) => WaveSkeletons.productCard(context),
          ),
        ),
      ];
    }

    if (state.status == MarketplaceStatus.failure) {
      final f = state.failure;
      final kind = f == null ? WaveFailureKind.serverError : waveFailureKind(f);
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: WaveStateView(
            state: WaveFailure(
              kind,
              detail: f == null ? null : failureText(context, f),
              onRetry: isRetryable(kind)
                  ? () => context
                      .read<MarketplaceBloc>()
                      .add(const MarketplaceStarted())
                  : null,
            ),
            content: const SizedBox.shrink(),
          ),
        ),
      ];
    }

    if (state.products.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: WaveStateView(
            state: state.isSearching
                ? WaveEmpty(
                    icon: Icons.search_off,
                    title: context.l10n.nothingMatched(state.query),
                    body: context.l10n.searchPrefixNoteProducts,
                    actionLabel: context.l10n.clearSearch,
                    onAction: _clearSearch,
                  )
                : WaveEmpty(
                    icon: Icons.storefront_outlined,
                    title: context.l10n.marketEmpty,
                    body: context.l10n.marketEmptyBody,
                    actionLabel: context.l10n.retry,
                    onAction: () => context
                        .read<MarketplaceBloc>()
                        .add(const MarketplaceStarted()),
                  ),
            content: const SizedBox.shrink(),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsetsDirectional.all(s.x16),
        sliver: SliverGrid.builder(
          gridDelegate: _grid(context),
          itemCount: state.products.length,
          itemBuilder: (context, i) {
            final p = state.products[i];
            return WaveProductCard(
              productId: p.id,
              imageUrl: p.primaryImage,
              title: p.title,
              priceMinor: p.priceMinor,
              isFavourite: state.favouriteIds.contains(p.id),
              onFavouriteToggle: () => context
                  .read<MarketplaceBloc>()
                  .add(MarketplaceFavouriteToggled(p.id)),
              onTap: () =>
                  context.push(Routes.productDetailPath(p.id), extra: p),
            );
          },
        ),
      ),
      if (state.status == MarketplaceStatus.loadingMore)
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(s.x16, 0, s.x16, s.x16),
          sliver: SliverGrid.builder(
            gridDelegate: _grid(context),
            itemCount: 2,
            itemBuilder: (context, __) => WaveSkeletons.productCard(context),
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: s.x64)),
    ];
  }
}
