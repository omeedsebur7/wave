import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/design_system/components/wave_skeleton.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
import 'package:wave/design_system/components/wave_ugc_text.dart';
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

  /// Reads in batches rather than all at once.
  ///
  /// Future.wait over every saved id opened one Firestore read per saved Reel
  /// simultaneously. A user with two hundred saves fired two hundred parallel
  /// reads on a connection this app is explicitly built to be gentle with.
  static const _batchSize = 12;

  Future<List<Reel>> _load() async {
    final ids = widget.savedReelIds;
    if (ids.isEmpty) return [];

    final repo = getIt<ReelRepository>();
    final reels = <Reel>[];

    for (var start = 0; start < ids.length; start += _batchSize) {
      final batch = ids.skip(start).take(_batchSize);
      final results = await Future.wait(batch.map(repo.fetchById));
      for (final r in results) {
        // A saved Reel whose author deleted it simply drops out. Showing a
        // broken tile would be worse than a slightly shorter list.
        final reel = r.valueOrNull;
        if (reel != null) reels.add(reel);
      }
    }

    return reels;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.spacing;

    final grid = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: s.x8,
      mainAxisSpacing: s.x8,
      childAspectRatio: 9 / 16,
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.savedReels)),
      body: FutureBuilder<List<Reel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GridView.builder(
              padding: EdgeInsetsDirectional.all(s.x12),
              gridDelegate: grid,
              itemCount: 6,
              itemBuilder: (_, __) => WaveSkeleton.line(
                height: double.infinity,
                radius: context.surfaces.radiusCard,
              ),
            );
          }

          // There was no error branch at all: a throw resolved to null data,
          // which fell through to `?? const <Reel>[]` and rendered the empty
          // state. A network failure looked identical to having saved nothing.
          if (snapshot.hasError) {
            return WaveStateView(
              state: WaveFailure(
                WaveFailureKind.serverError,
                onRetry: () => setState(() {}),
              ),
              content: const SizedBox.shrink(),
            );
          }

          final reels = snapshot.data ?? const <Reel>[];
          if (reels.isEmpty) {
            return WaveStateView(
              state: WaveEmpty(
                icon: Icons.bookmark_border,
                title: context.l10n.nothingSavedYet,
                body: context.l10n.savedReelsBody,
                actionLabel: context.l10n.watchSomeReels,
                onAction: () => context.go(Routes.reels),
              ),
              content: const SizedBox.shrink(),
            );
          }

          return GridView.builder(
            padding: EdgeInsetsDirectional.all(s.x12),
            gridDelegate: grid,
            itemCount: reels.length,
            itemBuilder: (context, i) => _SavedReelTile(reel: reels[i]),
          );
        },
      ),
    );
  }
}

class _SavedReelTile extends StatelessWidget {
  const _SavedReelTile({required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;
    final radius = BorderRadius.circular(context.surfaces.radiusCard);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Three across, so roughly a third of the screen each.
    final target = (MediaQuery.sizeOf(context).width / 3 * dpr).round();

    return Semantics(
      button: true,
      label: reel.caption,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => context.push(Routes.reelDetailPath(reel.id)),
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: radius,
                child: CachedNetworkImage(
                  imageUrl: reel.thumbnailUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: target,
                  placeholder: (_, __) => ColoredBox(color: c.skeletonBase),
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: c.surfaceSunken,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: c.textTertiary,
                    ),
                  ),
                ),
              ),
              if (reel.hasLinkedProduct)
                PositionedDirectional(
                  top: s.x8,
                  start: s.x8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius:
                          BorderRadius.circular(context.surfaces.radiusChip),
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: s.x8,
                        vertical: s.x2,
                      ),
                      // caption rather than a raw fontSize: 10. Nothing in the
                      // type scale is smaller than 12, and a one-off size is
                      // how a scale stops being one.
                      child: WaveUgcText(
                        context.l10n.shop,
                        style: t.caption.copyWith(color: c.onAccent),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
