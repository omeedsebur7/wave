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
import 'package:wave/core/theme/wave_surfaces.dart';
import 'package:wave/core/widgets/directional_chevron.dart';
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
    // The preview holds a native decoder like any other player. Not disposing
    // it leaks one per visit to this screen.
    _preview?.dispose();
    super.dispose();
  }

  /// Explains why the camera roll is needed before the OS asks.
  ///
  /// iOS gives one prompt: a denial cannot be re-requested in-app, only sent to
  /// Settings, which almost nobody does. Spending it cold — on a screen the
  /// user opened for another reason — wastes the only chance.
  Future<bool> _primeMediaAccess(BuildContext context) async {
    final onboarding = getIt<OnboardingService>();
    if (onboarding.hasPrimed(PrimedPermission.camera)) return true;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.chooseAVideo),
        content: Text(context.l10n.mediaAccessRationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.next),
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
      // A soft cap at the picker level. iOS honours it by trimming; Android
      // ignores it, which is why the real check happens below regardless.
      maxDuration: const Duration(
        seconds: ReelUploadService.maxDurationSeconds,
      ),
    );
    if (picked == null || !context.mounted) return;

    final file = File(picked.path);

    // Read the true duration from the file rather than trusting the picker.
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
          // Leaving mid-upload would abandon the transfer with no way back to
          // it. Uploading is short; blocking the gesture is less confusing than
          // silently losing the work.
          canPop: !state.isUploading,
          child: Scaffold(
            appBar: AppBar(
              title: Text(context.l10n.newReel),
              actions: [
                TextButton(
                  onPressed: state.canPublish
                      ? () => context
                          .read<UploadReelBloc>()
                          .add(const PublishRequested())
                      : null,
                  child: Text(context.l10n.publish),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _VideoSlot(
                  preview: _preview,
                  hasVideo: state.video != null,
                  onPick: () => _pickVideo(context),
                  onClear: () => _clearVideo(context),
                ),

                if (state.durationSeconds != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.durationOfMax(
                      state.durationSeconds!,
                      ReelUploadService.maxDurationSeconds,
                    ),
                    style: context.texts.bodySmall?.copyWith(
                      color: state.isTooLong ? c.error : c.textSecondary,
                    ),
                  ),
                ],

                if (state.isTooLong) ...[
                  const SizedBox(height: 12),
                  _Banner(
                    icon: Icons.error_outline,
                    colour: c.error,
                    // Names the real number and what to do, rather than a
                    // generic "invalid video".
                    text: context.l10n.videoTooLong(
                      state.durationSeconds!,
                      ReelUploadService.maxDurationSeconds,
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                TextField(
                  controller: _caption,
                  enabled: !state.isUploading,
                  maxLines: 3,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (v) =>
                      context.read<UploadReelBloc>().add(CaptionChanged(v)),
                  decoration: InputDecoration(
                    labelText: context.l10n.caption,
                    hintText: context.l10n.captionHint,
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 8),
                _ProductLinkTile(state: state),

                if (state.progress != null) ...[
                  const SizedBox(height: 24),
                  _UploadProgress(progress: state.progress!),
                ],

                const SizedBox(height: 40),
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
              borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
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
              borderRadius: BorderRadius.circular(WaveSurfaces.radiusCard),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius:
                      BorderRadius.circular(WaveSurfaces.radiusCard),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.video_library_outlined,
                          size: 40, color: c.textSecondary,),
                      const SizedBox(height: 12),
                      Text(context.l10n.chooseAVideo,
                          style: context.texts.labelMedium,),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.upToNSeconds(
                          ReelUploadService.maxDurationSeconds,
                        ),
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (hasVideo)
            PositionedDirectional(
              top: 8,
              end: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
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
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.sell_outlined, color: c.primary),
      title: Text(
        linked?.title ?? context.l10n.linkAProduct,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.labelMedium,
      ),
      subtitle: Text(
        linked == null
            // Names the consequence, because the connection between this step
            // and the Buy Now button is the entire point of the feature.
            ? context.l10n.linkAProductBody
            : context.l10n.linkedProductNote,
        style: context.texts.bodySmall,
      ),
      trailing: linked == null
          ? const DirectionalChevron()
          : IconButton(
              icon: const Icon(Icons.close, size: 20),
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
        // Null fraction renders an indeterminate bar. Server-side transcoding
        // has no measurable progress, and a fake bar is a lie the user
        // eventually notices.
        LinearProgressIndicator(value: progress.fraction),
        const SizedBox(height: 8),
        Text(uploadStageLabel(context, progress.stage),
            style: context.texts.bodySmall,),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(WaveSurfaces.radiusChip),
        border: Border.all(color: colour.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colour),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.texts.bodySmall?.copyWith(color: colour),
            ),
          ),
        ],
      ),
    );
  }
}
