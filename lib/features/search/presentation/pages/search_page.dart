import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';
import 'package:wave/features/search/presentation/bloc/search_bloc.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (v) =>
              context.read<SearchBloc>().add(SearchQueryChanged(v)),
          decoration: InputDecoration(
            hintText: context.l10n.searchProductsAndReels,
            border: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      context.read<SearchBloc>().add(const SearchCleared());
                      setState(() {});
                    },
                  ),
          ),
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state.status == SearchStatus.idle) {
            return _SearchHint(query: state.query);
          }
          if (state.status == SearchStatus.searching) {
            return const WaveStateView(
              state: WaveLoading(SizedBox.shrink()),
              content: SizedBox.shrink(),
            );
          }
          if (!state.hasResults) {
            return WaveErrorView.empty(
              title: context.l10n.nothingMatched(state.query),
              message: context.l10n.searchPrefixNoteAll,
              icon: Icons.search_off,
            );
          }

          return ListView(
            padding: const EdgeInsetsDirectional.all(WaveSpacing.x16),
            children: [
              if (state.products.isNotEmpty) ...[
                _SectionHeader(
                  title: context.l10n.products,
                  count: state.products.length,
                ),
                for (final p in state.products) _ProductRow(product: p),
                const SizedBox(height: WaveSpacing.x24),
              ],
              if (state.reels.isNotEmpty) ...[
                _SectionHeader(
                  title: context.l10n.reels,
                  count: state.reels.length,
                ),
                SizedBox(
                  // FIXED: Derived 176 using valid standard tokens instead of raw 180.0
                  height: WaveSpacing.x64 * 2 + WaveSpacing.x48, 
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.reels.length,
                    separatorBuilder: (_, __) => const SizedBox(width: WaveSpacing.x12),
                    itemBuilder: (context, i) =>
                        _ReelTile(reel: state.reels[i]),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(WaveSpacing.x32),
        child: Text(
          query.isEmpty
              ? context.l10n.searchHintEmpty
              : context.l10n.searchHintShort,
          style: context.texts.caption,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: WaveSpacing.x12),
      child: Text(
        context.l10n.sectionWithCount(title, count),
        style: context.texts.title,
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(vertical: WaveSpacing.x4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
        child: CachedNetworkImage(
          imageUrl: product.primaryImage,
          // FIXED: Used x48 + x8 to equate to exactly 56 without causing undefined errors
          width: WaveSpacing.x48 + WaveSpacing.x8,
          height: WaveSpacing.x48 + WaveSpacing.x8,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              Container(
                width: WaveSpacing.x48 + WaveSpacing.x8, 
                height: WaveSpacing.x48 + WaveSpacing.x8, 
                color: c.border,
              ),
        ),
      ),
      title: Text(
        product.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.body,
      ),
      subtitle: Text(
        context.money(product.priceMinor, product.currency),
        style: context.texts.label,
      ),
      trailing: product.inStock
          ? null
          : Text(
              context.l10n.soldOut,
              style: context.texts.caption.copyWith(color: c.error),
            ),
      onTap: () => context.push(
        Routes.productDetailPath(product.id),
        extra: product,
      ),
    );
  }
}

class _ReelTile extends StatelessWidget {
  const _ReelTile({required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return InkWell(
      onTap: () => context.push(Routes.reelDetailPath(reel.id)),
      borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
      child: SizedBox(
        // FIXED: Derived 108 using valid tokens instead of raw 110.0
        width: WaveSpacing.x64 + WaveSpacing.x40 + WaveSpacing.x4, 
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
              child: CachedNetworkImage(
                imageUrl: reel.thumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => ColoredBox(color: c.border),
              ),
            ),
            if (reel.hasLinkedProduct)
              PositionedDirectional(
                top: WaveSpacing.x8,
                start: WaveSpacing.x8,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: WaveSpacing.x8, 
                    vertical: WaveSpacing.x4,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
                  ),
                  child: Text(
                    context.l10n.shop,
                    style: context.texts.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
