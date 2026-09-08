import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/error/failure_to_state.dart'; 
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/services/bunny_stream_service.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/design_system/components/wave_sign_in_sheet.dart'; 
import 'package:wave/design_system/components/wave_skeleton.dart';
import 'package:wave/design_system/components/wave_state_view.dart';
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

  bool _pausedByUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _pool.pauseAll();
      return;
    }
    if (!_pausedByUser) _pool.resumeCurrent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pool.disposeAll();
    _pageController.dispose();
    super.dispose();
  }

  VideoPlayerController? _controllerFor(String reelId) {
    final player = _pool.playerFor(reelId);
    return player is VideoPlayerPooledPlayer ? player.controller : null;
  }

  void _togglePlayback(VideoPlayerController? controller) {
    if (controller == null || !controller.value.isInitialized) return;
    setState(() => _pausedByUser = controller.value.isPlaying);
    _pausedByUser ? controller.pause() : controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return Scaffold(
      backgroundColor: c.videoSurface,
      body: BlocConsumer<ReelsFeedBloc, ReelsFeedState>(
        listenWhen: (a, b) =>
            a.reels != b.reels ||
            a.currentIndex != b.currentIndex ||
            b.actionFailure != null,
        listener: (context, state) {
          final actionFailure = state.actionFailure;
          
          if (actionFailure != null) {
            if (isSignInPrompt(actionFailure.reason)) {
              final bloc = context.read<ReelsFeedBloc>();
              final reelId = state.reels[state.currentIndex].id;
              
              final retry = actionFailure.reason == FailureReason.signInToSaveReels
                  ? () => bloc.add(ReelSaveToggled(reelId))
                  : () => bloc.add(ReelLikeToggled(reelId));
                  
              WaveSignInSheet.show(context: context, onSuccess: retry);
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(failureText(context, actionFailure))),
                );
            }
          }

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
          if (state.reels.isEmpty) {
            return switch (state.status) {
              FeedStatus.initial || FeedStatus.loading => const _FeedSkeleton(),
              FeedStatus.failure => _FeedFailure(failure: state.failure),
              _ => WaveStateView(
                  state: WaveEmpty(
                    icon: Icons.videocam_off_outlined,
                    title: context.l10n.noReelsYet,
                    body: context.l10n.noReelsBody,
                    actionLabel: context.l10n.retry,
                    onAction: () => context
                        .read<ReelsFeedBloc>()
                        .add(const FeedRefreshed()),
                  ),
                  content: const SizedBox.shrink(),
                ),
            };
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: state.reels.length,
            onPageChanged: (i) {
              if (_pausedByUser) setState(() => _pausedByUser = false);
              context.read<ReelsFeedBloc>().add(FeedPageChanged(i));
            },
            itemBuilder: (context, index) {
              final reel = state.reels[index];
              final controller = _controllerFor(reel.id);
              return _ReelItem(
                reel: reel,
                controller: controller,
                isActive: index == state.currentIndex,
                pausedByUser: _pausedByUser && index == state.currentIndex,
                onTap: () => _togglePlayback(controller),
              );
            },
          );
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
    required this.pausedByUser,
    required this.onTap,
  });

  final Reel reel;
  final VideoPlayerController? controller;
  final bool isActive;
  final bool pausedByUser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final target = (MediaQuery.sizeOf(context).width * dpr).round();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: reel.thumbnailUrl,
            fit: BoxFit.cover,
            memCacheWidth: target,
            fadeInDuration: Duration.zero,
            errorWidget: (_, __, ___) => ColoredBox(color: c.videoSurface),
          ),

          if (controller != null)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller!,
              builder: (context, value, _) {
                if (!value.isInitialized) return const SizedBox.shrink();
                return RepaintBoundary(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: value.size.width,
                      height: value.size.height,
                      child: VideoPlayer(controller!),
                    ),
                  ),
                );
              },
            ),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, c.scrim],
                stops: const [0.55, 1],
              ),
            ),
          ),

          if (pausedByUser)
            Center(
              child: Icon(
                Icons.play_arrow_rounded,
                size: s.x64,
                color: c.onScrim,
              ),
            ),

          PositionedDirectional(
            start: s.x16,
            end: s.x12,
            bottom: s.x24,
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _Caption(reel: reel)),
                  SizedBox(width: s.x12),
                  ReelActionRail(reel: reel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final t = context.texts;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '@${reel.authorName}',
          style: t.bodyStrong.copyWith(color: c.onScrim),
        ),
        SizedBox(height: s.x4),
        Text(
          reel.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: t.body.copyWith(color: c.onScrim), // FIXED: bodyMedium to body
        ),
        if (reel.hasLinkedProduct) ...[
          SizedBox(height: s.x12),
          BuyNowButton(
            reelId: reel.id,
            productId: reel.linkedProductId!,
            sellerId: reel.authorId,
            priceMinor: reel.linkedProductPriceMinor,
            currency: reel.linkedProductCurrency,
          ),
        ],
      ],
    );
  }
}

class _FeedFailure extends StatelessWidget {
  const _FeedFailure({required this.failure});

  final Object? failure;

  @override
  Widget build(BuildContext context) {
    final f = failure;
    final kind = f is Failure ? waveFailureKind(f) : WaveFailureKind.serverError;
    
    return WaveStateView(
      state: WaveFailure(
        kind,
        detail: f is Failure ? failureText(context, f) : null,
        onRetry: isRetryable(kind)
            ? () => context.read<ReelsFeedBloc>().add(const FeedRefreshed())
            : null,
      ),
      content: const SizedBox.shrink(),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final s = context.spacing;

    return ColoredBox(
      color: c.videoSurface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const WaveSkeleton.line(height: double.infinity, radius: 0),
          PositionedDirectional(
            start: s.x16,
            end: s.x64,
            bottom: s.x24,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const WaveSkeleton(width: 140, height: 22), // FIXED: Raw int to standard float
                  SizedBox(height: s.x4),
                  const WaveSkeleton.line(height: 22), // FIXED
                  SizedBox(height: s.x4),
                  const WaveSkeleton(width: 200, height: 22), // FIXED
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
