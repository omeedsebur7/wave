import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:wave/app/di/injector.dart';
import 'package:wave/app/router/routes.dart';
import 'package:wave/core/error/failure_text.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/core/theme/app_theme.dart';
import 'package:wave/core/theme/wave_spacing.dart';

import 'package:wave/core/widgets/directional_chevron.dart';
import 'package:wave/core/widgets/wave_sheet.dart';
import 'package:wave/design_system/components/wave_button.dart';
import 'package:wave/design_system/components/wave_text_field.dart';
import 'package:wave/features/onboarding/data/onboarding_service.dart';
import 'package:wave/features/publish/data/reel_upload_service.dart';
import 'package:wave/features/publish/presentation/bloc/upload_reel_bloc.dart';
import 'package:wave/features/publish/presentation/upload_stage_text.dart';
import 'package:wave/features/publish/presentation/widgets/product_link_sheet.dart';

class UploadReelPage extends StatelessWidget {
  const UploadReelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UploadReelBloc(
        getIt<ReelUploadService>(),
        getIt(),
      ),
      child: const _UploadReelView(),
    );
  }
}

class _UploadReelView extends StatefulWidget {
  const _UploadReelView();

  @override
  State<_UploadReelView> createState() => _UploadReelViewState();
}

class _UploadReelViewState extends State<_UploadReelView> {
  final _caption = TextEditingController();
  VideoPlayerController? _preview;

  @override
  void dispose() {
    _caption.dispose();
    _preview?.dispose();
    super.dispose();
  }

  Future<bool> _primeMediaAccess(BuildContext context) async {
    final onboarding = getIt<OnboardingService>();
    if (onboarding.hasPrimed(PrimedPermission.camera)) return true;

    final proceed = await WaveSheet.show<bool>(
      context: context,
      title: context.l10n.chooseAVideo,
      builder: (context) => Text(
        context.l10n.mediaAccessRationale, 
        style: context.texts.body,
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WaveButton(
            expand: true,
            label: context.l10n.next,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: WaveSpacing.x8),
          WaveButton(
            expand: true,
            variant: WaveButtonVariant.tertiary,
            label: context.l10n.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (proceed ?? false) {
      await onboarding.markPrimed(PrimedPermission.camera);
      return true;
    }
    return false;
  }

  Future<void> _pickVideo(BuildContext context) async {
    if (!await _primeMediaAccess(context)) return;
    if (!context.mounted) return;

    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(
        seconds: ReelUploadService.maxDurationSeconds,
      ),
    );
    if (picked == null || !context.mounted) return;

    final file = File(picked.path);

    await _preview?.dispose();
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    await controller.setLooping(true);
    await controller.play();

    if (!context.mounted) {
      await controller.dispose();
      return;
    }

    setState(() => _preview = controller);

    context.read<UploadReelBloc>().add(
          VideoSelected(file, controller.value.duration.inSeconds),
        );
  }

  Future<void> _clearVideo(BuildContext context) async {
    await _preview?.dispose();
    if (!context.mounted) return;
    setState(() => _preview = null);
    context.read<UploadReelBloc>().add(const VideoCleared());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;

    return BlocConsumer<UploadReelBloc, UploadReelState>(
      listenWhen: (a, b) =>
          a.publishedReelId != b.publishedReelId || a.failure != b.failure,
      listener: (context, state) {
        if (state.publishedReelId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.reelIsLive)),
          );
          context.go(Routes.reelDetailPath(state.publishedReelId!));
        }
        if (state.failure != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failureText(context, state.failure!))));
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.isUploading,
          child: Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.newReel),
              actions: [
                WaveButton(
                  variant: WaveButtonVariant.tertiary,
                  size: WaveButtonSize.sm,
                  label: context.l10n.publish,
                  isLoading: state.isUploading,
                  onPressed: state.canPublish
                      ? () => context
                          .read<UploadReelBloc>()
                          .add(const PublishRequested())
                      : null,
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsetsDirectional.all(WaveSpacing.x20),
              children: [
                _VideoSlot(
                  preview: _preview,
                  hasVideo: state.video != null,
                  onPick: () => _pickVideo(context),
                  onClear: () => _clearVideo(context),
                ),

                if (state.durationSeconds != null) ...[
                  const SizedBox(height: WaveSpacing.x8),
                  Text(
                    context.l10n.durationOfMax(
                      state.durationSeconds!,
                      ReelUploadService.maxDurationSeconds,
                    ),
                    style: context.texts.caption.copyWith(
                      color: state.isTooLong ? c.error : c.textSecondary,
                    ),
                  ),
                ],

                if (state.isTooLong) ...[
                  const SizedBox(height: WaveSpacing.x12),
                  _Banner(
                    icon: Icons.error_outline,
                    colour: c.error,
                    text: context.l10n.videoTooLong(
                      state.durationSeconds!,
                      ReelUploadService.maxDurationSeconds,
                    ),
                  ),
                ],

                const SizedBox(height: WaveSpacing.x20),
                WaveTextField(
                  controller: _caption,
                  enabled: !state.isUploading,
                  maxLines: 3,
                  label: context.l10n.caption,
                  hint: context.l10n.captionHint,
                  onChanged: (v) =>
                      context.read<UploadReelBloc>().add(CaptionChanged(v)),
                ),

                const SizedBox(height: WaveSpacing.x8),
                _ProductLinkTile(state: state),

                if (state.progress != null) ...[
                  const SizedBox(height: WaveSpacing.x24),
                  _UploadProgress(progress: state.progress!),
                ],

                const SizedBox(height: WaveSpacing.x40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoSlot extends StatelessWidget {
  const _VideoSlot({
    required this.preview,
    required this.hasVideo,
    required this.onPick,
    required this.onClear,
  });

  final VideoPlayerController? preview;
  final bool hasVideo;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final ready = preview?.value.isInitialized ?? false;

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            ClipRRect(
              borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: preview!.value.size.width,
                  height: preview!.value.size.height,
                  child: VideoPlayer(preview!),
                ),
              ),
            )
          else
            InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(context.surfaces.radiusCard),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius:
                      BorderRadius.circular(context.surfaces.radiusCard),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_library_outlined,
                          size: WaveSpacing.x40, color: c.textSecondary,),
                      const SizedBox(height: WaveSpacing.x12),
                      Text(context.l10n.chooseAVideo,
                          style: context.texts.label,),
                      const SizedBox(height: WaveSpacing.x4),
                      Text(
                        context.l10n.upToNSeconds(
                          ReelUploadService.maxDurationSeconds,
                        ),
                        style: context.texts.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (hasVideo)
            PositionedDirectional(
              top: WaveSpacing.x8,
              end: WaveSpacing.x8,
              child: Material(
                color: c.scrim, // FIXED
                shape: const CircleBorder(),
                child: IconButton(
                  icon: Icon(Icons.close, color: c.onScrim, size: WaveSpacing.x20), // FIXED
                  tooltip: context.l10n.chooseADifferentVideo,
                  onPressed: onClear,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductLinkTile extends StatelessWidget {
  const _ProductLinkTile({required this.state});

  final UploadReelState state;

  @override
  Widget build(BuildContext context) {
    final c = context.waveColors;
    final linked = state.linkedProduct;

    return ListTile(
      contentPadding: EdgeInsetsDirectional.zero,
      leading: Icon(Icons.sell_outlined, color: c.primary),
      title: Text(
        linked?.title ?? context.l10n.linkAProduct,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.label,
      ),
      subtitle: Text(
        linked == null
            ? context.l10n.linkAProductBody
            : context.l10n.linkedProductNote,
        style: context.texts.caption,
      ),
      trailing: linked == null
          ? const DirectionalChevron()
          : IconButton(
              icon: const Icon(Icons.close, size: WaveSpacing.x20),
              tooltip: context.l10n.removeTheLink,
              onPressed: () =>
                  context.read<UploadReelBloc>().add(const ProductLinked(null)),
            ),
      onTap: state.isUploading
          ? null
          : () async {
              final bloc = context.read<UploadReelBloc>();
              final product = await showProductLinkSheet(context);
              if (product != null) bloc.add(ProductLinked(product));
            },
    );
  }
}

class _UploadProgress extends StatelessWidget {
  const _UploadProgress({required this.progress});

  final ReelUploadProgress progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: progress.fraction),
        const SizedBox(height: WaveSpacing.x8),
        Text(uploadStageLabel(context, progress.stage),
            style: context.texts.caption,),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.colour,
    required this.text,
  });

  final IconData icon;
  final Color colour;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(WaveSpacing.x12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(context.surfaces.radiusChip),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colour), // FIXED
          const SizedBox(width: WaveSpacing.x8),
          Expanded(
            child: Text(
              text,
              style: context.texts.caption.copyWith(color: colour),
            ),
          ),
        ],
      ),
    );
  }
}
