import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:http/http.dart' as http;
import 'package:video_compress/video_compress.dart';
import 'package:wave/core/error/exceptions.dart';
import 'package:wave/core/error/failures.dart';
import 'package:wave/core/network/connectivity_service.dart';
import 'package:wave/core/utils/result.dart';

/// Progress through the multi-step Bunny ingest, so the UI can say what is
/// actually happening rather than showing one undifferentiated bar for a
/// process that has very different stages.
enum ReelUploadStage {
  validating,
  compressing,
  requestingSlot,
  uploading,
  processing,
  publishing,
  done,
}

class ReelUploadProgress {
  const ReelUploadProgress(this.stage, {this.fraction});
  final ReelUploadStage stage;

  /// 0–1 where meaningful. Null for stages with no measurable progress —
  /// showing a fake bar for server-side transcoding is a lie the user
  /// eventually notices.
  final double? fraction;

  // Deliberately carries no `label`.
  //
  // This is a data-layer value object and has no `BuildContext`, so a label
  // defined here is guaranteed never to translate — the same trap already
  // removed from four enums and `ProductSort`. Resolved by
  // `uploadStageLabel` in the presentation layer.
}

/// Reel ingest to Bunny Stream (§4, §6).
///
/// The flow, and why it has this shape:
///
/// 1. **Validate locally.** The 60-second cap is checked before anything is
///    compressed or uploaded, so a user with a 3-minute clip finds out in a
///    second rather than after a long upload on a slow connection.
/// 2. **Compress locally.** Smaller source files reach Bunny, which cuts
///    upload time on a poor connection and storage cost at rest.
/// 3. **Ask the backend for an upload slot.** A Cloud Function creates the
///    Bunny video object and returns a short-lived signed upload URL. The Bunny
///    API key never touches the device — same principle as playback signing.
/// 4. **Upload directly to Bunny.** The bytes go device → Bunny, never through
///    our backend. Proxying video through a Cloud Function would be slow and
///    expensive for no security benefit, since the URL is already scoped and
///    time-limited.
/// 5. **Poll for encoding.** Bunny transcodes asynchronously. The Reel document
///    is only written once the rendition ladder exists, so the feed never shows
///    a Reel that cannot play.
class ReelUploadService {
  ReelUploadService(this._functions, this._connectivity);

  final FirebaseFunctions _functions;
  final ConnectivityService _connectivity;

  static const maxDurationSeconds = 60;

  /// Above 720p rarely reads as sharper on a phone-sized full-screen Reel and
  /// meaningfully raises storage and egress cost, so we never send more than we
  /// need Bunny to keep (§6).
  static const targetMaxHeight = 720;

  Future<Result<String>> upload({
    required File videoFile,
    required int durationSeconds,
    required String caption,
    required void Function(ReelUploadProgress) onProgress, String? linkedProductId,
  }) async {
    // ── 1. Validate ──────────────────────────────────────────────────────
    onProgress(const ReelUploadProgress(ReelUploadStage.validating));

    if (durationSeconds > maxDurationSeconds) {
      // Both numbers travel on the failure: the translated sentence quotes
      // them, and `core` must not import this service to find the limit.
      return Err(
        ServerFailure(
          'Video longer than maxDurationSeconds',
          reason: FailureReason.videoTooLong,
          amount: durationSeconds,
          limit: maxDurationSeconds,
        ),
      );
    }

    if (!await _connectivity.isOnline) {
      // Fail fast and honestly. Queuing a multi-megabyte upload for "later" is
      // a promise that is hard to keep and worse to break silently.
      return const Err(
        NetworkFailure(
          'Offline before upload',
          FailureReason.uploadNeedsConnection,
        ),
      );
    }

    try {
      // ── 2. Compress ────────────────────────────────────────────────────
      onProgress(const ReelUploadProgress(ReelUploadStage.compressing));
      final compressed = await _compress(videoFile);

      // ── 3. Request an upload slot ──────────────────────────────────────
      onProgress(const ReelUploadProgress(ReelUploadStage.requestingSlot));
      final slot = await _functions
          .httpsCallable('createBunnyUploadSlot')
          .call<Map<String, dynamic>>({
        'title': caption.isEmpty ? 'Reel' : caption,
        'durationSeconds': durationSeconds,
      });

      final videoId = slot.data['videoId'] as String;
      final uploadUrl = slot.data['uploadUrl'] as String;

      // ── 4. Upload straight to Bunny ────────────────────────────────────
      await _putFile(
        uploadUrl: uploadUrl,
        file: compressed,
        onProgress: (fraction) => onProgress(
          ReelUploadProgress(ReelUploadStage.uploading, fraction: fraction),
        ),
      );

      // ── 5. Wait for the rendition ladder ───────────────────────────────
      onProgress(const ReelUploadProgress(ReelUploadStage.processing));
      final encoded = await _awaitEncoding(videoId);
      if (!encoded) {
        return const Err(
          ServerFailure(
            'Bunny encoding did not finish in the polling window',
            reason: FailureReason.videoStillProcessing,
          ),
        );
      }

      // ── 6. Publish the Reel document ───────────────────────────────────
      onProgress(const ReelUploadProgress(ReelUploadStage.publishing));
      final published = await _functions
          .httpsCallable('publishReel')
          .call<Map<String, dynamic>>({
        'bunnyVideoId': videoId,
        'caption': caption,
        'durationSeconds': durationSeconds,
        'linkedProductId': linkedProductId,
      });

      onProgress(const ReelUploadProgress(ReelUploadStage.done, fraction: 1));
      return Success(published.data['reelId'] as String);
    } on FirebaseFunctionsException catch (e) {
      return Err(
        switch (e.code) {
          'resource-exhausted' => const RateLimitedFailure(
              'publishReel rate limited',
              reason: FailureReason.publishThrottled,
            ),
          'permission-denied' => const PermissionFailure(
              'publishReel denied',
              FailureReason.publishNotAllowed,
            ),
          _ => ServerFailure(
              e.message ?? 'Upload failed',
              code: e.code,
              reason: FailureReason.uploadFailed,
            ),
        },
      );
    } catch (e) {
      return Err(
        ServerFailure(
          'Upload failed: $e',
          reason: FailureReason.uploadFailed,
        ),
      );
    }
  }

  /// Transcodes down to roughly 720p before upload.
  ///
  /// Returns the ORIGINAL file if compression fails or somehow produces a
  /// larger file. A failed compression should cost quality, never the post —
  /// losing someone's video to an encoder edge case is far worse than
  /// uploading a few extra megabytes.
  Future<File> _compress(File source) async {
    try {
      final info = await VideoCompress.compressVideo(
        source.path,
        quality: VideoQuality.MediumQuality, // ~720p
        includeAudio: true,
      );

      final compressed = info?.file;
      if (compressed == null) return source;

      final originalSize = await source.length();
      final newSize = await compressed.length();

      return newSize < originalSize ? compressed : source;
    } catch (_) {
      // A failed compression costs quality, never the post. Losing someone's
      // video to an encoder edge case is far worse than uploading a few extra
      // megabytes.
      return source;
    }
  }

  /// Streams the file to Bunny with a plain PUT.
  ///
  /// Streamed rather than loaded into memory: a 60-second video can be tens of
  /// megabytes, and reading it all into a byte list to send is how mid-range
  /// Android devices die during upload.
  Future<void> _putFile({
    required String uploadUrl,
    required File file,
    required void Function(double) onProgress,
  }) async {
    final length = await file.length();
    var sent = 0;

    final request = http.StreamedRequest('PUT', Uri.parse(uploadUrl))
      ..headers['Content-Type'] = 'application/octet-stream'
      ..contentLength = length;

    final reader = file.openRead().listen(
      (chunk) {
        request.sink.add(chunk);
        sent += chunk.length;
        onProgress(sent / length);
      },
      onDone: request.sink.close,
      onError: (Object e) => request.sink.addError(e),
      cancelOnError: true,
    );

    try {
      final response = await request.send();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerException(
          'Bunny rejected the upload (${response.statusCode})',
        );
      }
    } finally {
      // If `send` threw — a dropped connection mid-upload, which on a mobile
      // network is the normal case rather than the exception — the file read
      // would otherwise carry on to the end, holding a file handle and feeding
      // chunks into a sink nobody is draining. On a 60-second video that is
      // tens of megabytes read for nothing.
      await reader.cancel();
    }
  }

  /// Polls the backend for encoding status.
  ///
  /// Backs off rather than hammering: a 40-second clip usually finishes in
  /// well under a minute, but a busy queue can take longer, and a tight poll
  /// loop on a mobile connection is a battery and data cost for no benefit.
  Future<bool> _awaitEncoding(
    String videoId, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    var delay = const Duration(seconds: 2);

    while (DateTime.now().isBefore(deadline)) {
      final status = await _functions
          .httpsCallable('bunnyVideoStatus')
          .call<Map<String, dynamic>>({'videoId': videoId});

      if (status.data['ready'] == true) return true;
      if (status.data['failed'] == true) return false;

      await Future<void>.delayed(delay);
      delay = Duration(
        seconds: (delay.inSeconds * 1.5).round().clamp(2, 15),
      );
    }
    return false;
  }
}
