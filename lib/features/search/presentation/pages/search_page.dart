import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/utils/money.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
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
            return const Center(child: CircularProgressIndicator());
          }
          if (!state.hasResults) {
            return WaveErrorView.empty(
              title: context.l10n.nothingMatched(state.query),
              // Names the actual limitation instead of implying the catalogue
              // is empty. Prefix-only search fails in a specific, explainable
              // way, and saying so beats letting people conclude we have
              // nothing.
              message: context.l10n.searchPrefixNoteAll,
              icon: Icons.search_off,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.products.isNotEmpty) ...[
                _SectionHeader(
                  title: context.l10n.products,
                  count: state.products.length,
                ),
                for (final p in state.products) _ProductRow(product: p),
                const SizedBox(height: 24),
              ],
              if (state.reels.isNotEmpty) ...[
                _SectionHeader(
                  title: context.l10n.reels,
                  count: state.reels.length,
                ),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.reels.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
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
        padding: const EdgeInsets.all(32),
        child: Text(
          query.isEmpty
              ? context.l10n.searchHintEmpty
              : context.l10n.searchHintShort,
          style: context.texts.bodySmall,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        context.l10n.sectionWithCount(title, count),
        style: context.texts.titleMedium,
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
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
        child: CachedNetworkImage(
          imageUrl: product.primaryImage,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              Container(width: 56, height: 56, color: c.border),
        ),
      ),
      title: Text(
        product.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.bodyMedium,
      ),
      subtitle: Text(
        context.money(product.priceMinor, product.currency),
        style: context.texts.labelMedium,
      ),
      trailing: product.inStock
          ? null
          : Text(
              context.l10n.soldOut,
              style: context.texts.bodySmall?.copyWith(color: c.error),
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
      borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
      child: SizedBox(
        width: 110,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
              child: CachedNetworkImage(
                imageUrl: reel.thumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => ColoredBox(color: c.border),
              ),
            ),
            // A Reel with a linked product is the one that can be bought from,
            // so it is worth flagging in a result list.
            if (reel.hasLinkedProduct)
              PositionedDirectional(
                top: 6,
                start: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.l10n.shop,
                    style: context.texts.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
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
