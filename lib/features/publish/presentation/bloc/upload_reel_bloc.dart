import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wave/core/analytics/analytics_events.dart';
import 'package:wave/core/analytics/analytics_service.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/features/marketplace/domain/entities/product.dart';
import 'package:wave/features/publish/data/reel_upload_service.dart';

sealed class UploadReelEvent extends Equatable {
  const UploadReelEvent();
  @override
  List<Object?> get props => [];
}

class VideoSelected extends UploadReelEvent {
  const VideoSelected(this.file, this.durationSeconds);
  final File file;
  final int durationSeconds;
  @override
  List<Object?> get props => [file.path, durationSeconds];
}

class VideoCleared extends UploadReelEvent {
  const VideoCleared();
}

class CaptionChanged extends UploadReelEvent {
  const CaptionChanged(this.caption);
  final String caption;
  @override
  List<Object?> get props => [caption];
}

class ProductLinked extends UploadReelEvent {
  const ProductLinked(this.product);
  final Product? product;
  @override
  List<Object?> get props => [product?.id];
}

class PublishRequested extends UploadReelEvent {
  const PublishRequested();
}

class _ProgressReported extends UploadReelEvent {
  const _ProgressReported(this.progress);
  final ReelUploadProgress progress;
  @override
  List<Object?> get props => [progress.stage, progress.fraction];
}

class UploadReelState extends Equatable {
  const UploadReelState({
    this.video,
    this.durationSeconds,
    this.caption = '',
    this.linkedProduct,
    this.progress,
    this.publishedReelId,
    this.failure,
  });

  final File? video;
  final int? durationSeconds;
  final String caption;
  final Product? linkedProduct;
  final ReelUploadProgress? progress;
  final String? publishedReelId;
  final Failure? failure;

  bool get isUploading =>
      progress != null && progress!.stage != ReelUploadStage.done;

  bool get isTooLong =>
      durationSeconds != null &&
      durationSeconds! > ReelUploadService.maxDurationSeconds;

  bool get canPublish => video != null && !isTooLong && !isUploading;

  UploadReelState copyWith({
    File? video,
    int? durationSeconds,
    String? caption,
    Product? linkedProduct,
    ReelUploadProgress? progress,
    String? publishedReelId,
    Failure? failure,
    bool clearVideo = false,
    bool clearProduct = false,
    bool clearProgress = false,
    bool clearFailure = false,
  }) =>
      UploadReelState(
        video: clearVideo ? null : (video ?? this.video),
        durationSeconds:
            clearVideo ? null : (durationSeconds ?? this.durationSeconds),
        caption: caption ?? this.caption,
        linkedProduct:
            clearProduct ? null : (linkedProduct ?? this.linkedProduct),
        progress: clearProgress ? null : (progress ?? this.progress),
        publishedReelId: publishedReelId ?? this.publishedReelId,
        // FIXED: Using boolean flags to clear safely
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [
        video?.path,
        durationSeconds,
        caption,
        linkedProduct?.id,
        progress?.stage,
        progress?.fraction,
        publishedReelId,
        failure,
      ];
}

class UploadReelBloc extends Bloc<UploadReelEvent, UploadReelState> {
  UploadReelBloc(this._service, this._analytics)
      : super(const UploadReelState()) {
    on<VideoSelected>(
      (e, emit) => emit(
        state.copyWith(
          video: e.file,
          durationSeconds: e.durationSeconds,
          clearFailure: true,
        ),
      ),
    );
    on<VideoCleared>(
      (e, emit) => emit(state.copyWith(clearVideo: true, clearFailure: true)),
    );
    on<CaptionChanged>((e, emit) => emit(state.copyWith(caption: e.caption)));
    on<ProductLinked>(_onProductLinked);
    on<PublishRequested>(_onPublish);
    on<_ProgressReported>(
      (e, emit) => emit(state.copyWith(progress: e.progress)),
    );
  }

  final ReelUploadService _service;
  final AnalyticsService _analytics;

  void _onProductLinked(ProductLinked e, Emitter<UploadReelState> emit) {
    emit(
      e.product == null
          ? state.copyWith(clearProduct: true)
          : state.copyWith(linkedProduct: e.product),
    );

    if (e.product != null) {
      _analytics.log(
        AnalyticsEvents.productLinkedToReel,
        params: {AnalyticsParams.productId: e.product!.id},
      );
    }
  }

  Future<void> _onPublish(
    PublishRequested e,
    Emitter<UploadReelState> emit,
  ) async {
    if (!state.canPublish) return;

    emit(
      state.copyWith(
        progress: const ReelUploadProgress(ReelUploadStage.validating),
        clearFailure: true,
      ),
    );

    final result = await _service.upload(
      videoFile: state.video!,
      durationSeconds: state.durationSeconds!,
      caption: state.caption,
      linkedProductId: state.linkedProduct?.id,
      onProgress: (progress) => add(_ProgressReported(progress)),
    );

    // FIXED: Protect against the bloc being closed mid-upload (§8.5)
    if (emit.isDone) return;

    result.fold(
      (f) => emit(state.copyWith(failure: f, clearProgress: true)),
      (reelId) {
        _analytics.log(
          AnalyticsEvents.reelPublished,
          params: {
            AnalyticsParams.reelId: reelId,
            if (state.linkedProduct != null)
              AnalyticsParams.productId: state.linkedProduct!.id,
          },
        );
        emit(
          state.copyWith(
            publishedReelId: reelId,
            progress: const ReelUploadProgress(
              ReelUploadStage.done,
              fraction: 1,
            ),
          ),
        );
      },
    );
  }
}
