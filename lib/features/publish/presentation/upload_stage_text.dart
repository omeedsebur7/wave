import 'package:flutter/widgets.dart';
import 'package:wave/core/l10n_extension.dart';
import 'package:wave/features/publish/data/reel_upload_service.dart';

/// Resolves an upload stage to text the person watching can act on.
///
/// Lives here rather than on [ReelUploadProgress] because that is a data-layer
/// value object with no `BuildContext` — a label defined there could never
/// translate. The sixth place in this codebase where a label sat next to its
/// value and had to be moved; it reads as good cohesion and is the one reliable
/// way to make a string permanently English.
///
/// The stages are named separately rather than collapsed into "Uploading…"
/// because they behave differently from the user's point of view: compression
/// is local and fast, the upload consumes their data allowance, and processing
/// happens server-side and does not need them to stay on the screen. Telling
/// them which one they are in is the difference between a progress bar and an
/// explanation.
String uploadStageLabel(BuildContext context, ReelUploadStage stage) =>
    switch (stage) {
      ReelUploadStage.validating => context.l10n.uploadValidating,
      ReelUploadStage.compressing => context.l10n.uploadCompressing,
      ReelUploadStage.requestingSlot => context.l10n.uploadPreparing,
      ReelUploadStage.uploading => context.l10n.uploadUploading,
      // The only stage that tells them they can leave, because it is the only
      // one that continues without the app in the foreground.
      ReelUploadStage.processing => context.l10n.uploadProcessing,
      ReelUploadStage.publishing => context.l10n.uploadPublishing,
      ReelUploadStage.done => context.l10n.uploadDone,
    };
