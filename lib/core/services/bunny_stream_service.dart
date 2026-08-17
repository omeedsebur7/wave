import 'package:cloud_functions/cloud_functions.dart';
import 'package:injectable/injectable.dart';
import 'package:wave/core/config/remote_config_keys.dart';
import 'package:wave/core/network/connectivity_service.dart';
import 'package:wave/core/services/remote_config_service.dart';

/// Bunny Stream playback (§6 — Video Infrastructure).
///
/// Two things this class deliberately does NOT do:
///
/// 1. It never holds the Bunny token-authentication secret. The signing key
///    lives in a Cloud Function and nowhere else — the same principle that
///    keeps write access off unauthenticated clients in Security Rules. A key
///    shipped in the app binary is a public key, whatever the obfuscation.
/// 2. It doesn't use a Bunny SDK. Bunny returns a plain HLS .m3u8 URL, which
///    video_player handles natively via ExoPlayer/AVPlayer.
@lazySingleton
class BunnyStreamService {
  BunnyStreamService(this._functions, this._connectivity, this._config);

  final FirebaseFunctions _functions;
  final ConnectivityService _connectivity;
  final RemoteConfigService _config;

  final _signedCache = <String, _SignedUrl>{};

  /// Asks the backend to sign a short-lived playback URL for [videoId].
  ///
  /// Cached in-memory until shortly before expiry so back-scrolling through a
  /// feed doesn't fire a function call per swipe.
  Future<String> playbackUrl(String videoId, {int? maxHeight}) async {
    // Keyed by resolution too. Without that, moving from wifi to cellular
    // would serve the cached full-quality URL for the rest of the session —
    // the Data Saver setting would appear to do nothing until a restart.
    final key = maxHeight == null ? videoId : '$videoId@$maxHeight';
    final cached = _signedCache[key];
    if (cached != null && cached.isStillFresh) return cached.url;

    final result = await _functions
        .httpsCallable('signBunnyPlaybackUrl')
        .call<Map<String, dynamic>>({
      'videoId': videoId,
      if (maxHeight != null) 'maxHeight': maxHeight,
    });

    final url = result.data['url'] as String;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      (result.data['expiresAtMs'] as num).toInt(),
    );
    _signedCache[key] = _SignedUrl(url, expiresAt);
    return url;
  }

  /// Data Saver (§6 — cost/quality control). On cellular we cap the ladder so
  /// the player never pulls the 720p rendition. Above 720p is skipped entirely
  /// at the library level anyway — on a phone-sized full-screen Reel it rarely
  /// reads as sharper, and it meaningfully raises egress cost.
  Future<int> maxHeightForCurrentNetwork({bool? dataSaverEnabled}) async {
    // The user's own setting wins. Remote Config only supplies the DEFAULT for
    // people who have never touched it — which is the lever that matters,
    // since almost nobody opens video settings.
    final saver = dataSaverEnabled ??
        _config.getBool(RemoteConfigKeys.dataSaverDefaultOnCellular);

    final quality = await _connectivity.current();
    if (quality == ConnectionQuality.cellular && saver) return 480;
    return 720;
  }

  void clearCache() => _signedCache.clear();
}

class _SignedUrl {
  _SignedUrl(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;

  /// 30s of headroom so a URL never expires mid-buffer.
  bool get isStillFresh =>
      DateTime.now().isBefore(expiresAt.subtract(const Duration(seconds: 30)));
}
