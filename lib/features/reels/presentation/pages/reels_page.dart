import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/services/bunny_stream_service.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/widgets/wave_error_view.dart';
import 'package:wave/features/reels/domain/entities/reel.dart';
import 'package:wave/features/reels/presentation/bloc/reels_feed_bloc.dart';
import 'package:wave/features/reels/presentation/widgets/buy_now_button.dart';
import 'package:wave/features/reels/presentation/widgets/reel_action_rail.dart';
import 'package:wave/features/reels/presentation/widgets/reel_controller_pool.dart';

class ReelsPage extends StatelessWidget {
  const ReelsPage({this.initialReelId, super.key});

  final String? initialReelId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReelsFeedBloc>()..add(const FeedStarted()),
      child: _ReelsView(initialReelId: initialReelId),
    );
  }
}

class _ReelsView extends StatefulWidget {
  const _ReelsView({this.initialReelId});
  final String? initialReelId;

  @override
  State<_ReelsView> createState() => _ReelsViewState();
}

class _ReelsViewState extends State<_ReelsView> with WidgetsBindingObserver {
  late final PageController _pageController = PageController();
  late final ReelControllerPool _pool = ReelControllerPool(
    getIt<BunnyStreamService>(),
    onFirstFrame: (elapsed) => getIt<AnalyticsService>().log(
      AnalyticsEvents.videoTimeToFirstFrame,
      params: {AnalyticsParams.durationMs: elapsed.inMilliseconds},
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding the app must stop playback and audio — otherwise a Reel
    // keeps talking from the user's pocket.
    if (state != AppLifecycleState.resumed) _pool.pauseAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Nothing survives the feed. Every native player is released here.
    _pool.disposeAll();
    _pageController.dispose();
    super.dispose();
  }

  /// Unwraps the pooled adapter back to the concrete controller the
  /// VideoPlayer widget needs. Null while a player is still initialising, which
  /// is exactly when the thumbnail underneath is doing its job.
  VideoPlayerController? _controllerFor(String reelId) {
    final player = _pool.playerFor(reelId);
    return player is VideoPlayerPooledPlayer ? player.controller : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: BlocConsumer<ReelsFeedBloc, ReelsFeedState>(
        listenWhen: (a, b) => a.reels != b.reels || a.currentIndex != b.currentIndex,
        listener: (context, state) {
          if (state.reels.isEmpty) return;
          _pool.onPageChanged(
            index: state.currentIndex,
            reels: [
              for (final r in state.reels)
                (reelId: r.id, bunnyVideoId: r.bunnyVideoId),
            ],
          );
        },
        builder: (context, state) {
          return switch (state.status) {
            FeedStatus.initial || FeedStatus.loading => const _FeedSkeleton(),
            FeedStatus.failure => WaveErrorView(
                title: context.l10n.reelsNotLoaded,
                message: context.l10n.errorNoConnectionBody,
                onRetry: () =>
                    context.read<ReelsFeedBloc>().add(const FeedRefreshed()),
              ),
            _ when state.reels.isEmpty => WaveErrorView.empty(
                title: context.l10n.noReelsYet,
                message: context.l10n.noReelsBody,
              ),
            _ => PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: state.reels.length,
                onPageChanged: (i) =>
                    context.read<ReelsFeedBloc>().add(FeedPageChanged(i)),
                itemBuilder: (context, index) => _ReelItem(
                  reel: state.reels[index],
                  controller: _controllerFor(state.reels[index].id),
                  isActive: index == state.currentIndex,
                ),
              ),
          };
        },
      ),
    );
  }
}

class _ReelItem extends StatelessWidget {
  const _ReelItem({
    required this.reel,
    required this.controller,
    required this.isActive,
  });

  final Reel reel;
  final VideoPlayerController? controller;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final ready = controller?.value.isInitialized ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        // The thumbnail is always painted underneath. That's what makes a swipe
        // feel instant even before the first video frame decodes — the user
        // sees the Reel, not a black rectangle.
        CachedNetworkImage(
          imageUrl: reel.thumbnailUrl,
          fit: BoxFit.cover,
          fadeInDuration: Duration.zero,
        ),
        if (ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller!.value.size.width,
              height: controller!.value.size.height,
              child: VideoPlayer(controller!),
            ),
          ),

        // Scrim so white caption text stays legible over any video.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
              stops: [0.55, 1],
            ),
          ),
        ),

        // The action rail belongs on the trailing edge, which is the LEFT of
        // the screen in Arabic and Kurdish — where the thumb of an RTL reader
        // expects it.
        PositionedDirectional(
          end: 12,
          bottom: 120,
          child: ReelActionRail(reel: reel),
        ),

        // 80 of clearance on the trailing side, for the rail above.
        PositionedDirectional(
          start: 16,
          end: 80,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '@${reel.authorName}',
                style: context.texts.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                reel.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.texts.bodyMedium?.copyWith(color: Colors.white),
              ),
              // Buy Now appears if, and only if, the publisher linked a product.
              if (reel.hasLinkedProduct) ...[
                const SizedBox(height: 12),
                BuyNowButton(
                  reelId: reel.id,
                  productId: reel.linkedProductId!,
                  sellerId: reel.authorId,
                  priceMinor: reel.linkedProductPriceMinor,
                  currency: reel.linkedProductCurrency,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
        ),
      ),
    );
  }
}
