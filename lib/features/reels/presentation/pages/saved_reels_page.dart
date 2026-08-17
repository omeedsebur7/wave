import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/core/widgets/wave_skeleton.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';
import 'package:wave/features/reels/domain/repositories/reel_repository.dart';

/// Reels the user saved to favourites (§4).
///
/// A grid of thumbnails rather than a playable feed: this is a list you scan to
/// find one thing, not a feed you scroll. Instantiating video controllers for a
/// screen nobody watches would spend native memory for nothing.
class SavedReelsPage extends StatefulWidget {
  const SavedReelsPage({required this.savedReelIds, super.key});

  final List<String> savedReelIds;

  @override
  State<SavedReelsPage> createState() => _SavedReelsPageState();
}

class _SavedReelsPageState extends State<SavedReelsPage> {
  late final Future<List<Reel>> _future = _load();

  Future<List<Reel>> _load() async {
    if (widget.savedReelIds.isEmpty) return [];

    final repo = getIt<ReelRepository>();
    final results = await Future.wait(widget.savedReelIds.map(repo.fetchById));

    return [
      for (final r in results)
        // A saved Reel whose author deleted it simply drops out. Showing a
        // broken tile would be worse than a slightly shorter list.
        if (r.valueOrNull != null) r.valueOrNull!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.savedReels)),
      body: FutureBuilder<List<Reel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: _grid,
              itemCount: 6,
              itemBuilder: (_, __) => const WaveSkeleton(
                width: double.infinity,
                height: double.infinity,
                radius: WaveSurfaces.radiusCard,
              ),
            );
          }

          final reels = snapshot.data ?? const <Reel>[];
          if (reels.isEmpty) {
            return WaveErrorView.empty(
              title: context.l10n.nothingSavedYet,
              message: context.l10n.savedReelsBody,
              icon: Icons.bookmark_border,
              retryLabel: context.l10n.watchSomeReels,
              onRetry: () => context.go(Routes.reels),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: _grid,
            itemCount: reels.length,
            itemBuilder: (context, i) => _SavedReelTile(reel: reels[i]),
          );
        },
      ),
    );
  }

  static const _grid = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 9 / 16,
  );
}

class _SavedReelTile extends StatelessWidget {
  const _SavedReelTile({required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return InkWell(
      onTap: () => context.push(Routes.reelDetailPath(reel.id)),
      borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
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
          if (reel.hasLinkedProduct)
            PositionedDirectional(
              top: 6,
              start: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
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
    );
  }
}
