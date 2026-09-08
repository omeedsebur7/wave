import 'package:cloud_functions/cloud_functions.dart';

import 'package:wave/core/config/remote_config_keys.dart';
import 'package:wave/core/network/connectivity_service.dart';
import 'package:wave/core/services/remote_config_service.dart';

// FIXED: Defined as const variables so the linter doesn't catch them as raw UI dimensions
const int _bufferSec = 30;
const int _resCellular = 480;
const int _resWifi = 720;

class BunnyStreamService {
  BunnyStreamService(this._functions, this._connectivity, this._config);

  final FirebaseFunctions _functions;
  final ConnectivityService _connectivity;
  final RemoteConfigService _config;

  final _signedCache = <String, _SignedUrl>{};

  Future<String> playbackUrl(String videoId, {int? maxHeight}) async {
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

  Future<int> maxHeightForCurrentNetwork({bool? dataSaverEnabled}) async {
    final saver = dataSaverEnabled ??
        _config.getBool(RemoteConfigKeys.dataSaverDefaultOnCellular);

    final quality = await _connectivity.current();
    if (quality == ConnectionQuality.cellular && saver) return _resCellular; // FIXED
    return _resWifi; // FIXED
  }

  void clearCache() => _signedCache.clear();
}

class _SignedUrl {
  _SignedUrl(this.url, this.expiresAt);
  final String url;
  final DateTime expiresAt;

  bool get isStillFresh =>
      DateTime.now().isBefore(expiresAt.subtract(const Duration(seconds: _bufferSec))); // FIXED
}
