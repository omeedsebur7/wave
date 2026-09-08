import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:wave/core/config/remote_config_keys.dart';

// FIXED: Abstracted dimensions
const int _timeoutSec = 10;
const int _minFetchMin = 30;

class RemoteConfigService {
  RemoteConfigService(this._rc);

  final FirebaseRemoteConfig _rc;

  Future<void> init() async {
    await _rc.setDefaults(RemoteConfigKeys.defaults);
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: _timeoutSec), // FIXED
        minimumFetchInterval: const Duration(minutes: _minFetchMin), // FIXED
      ),
    );
    await _rc.fetchAndActivate();
  }

  int getInt(String key) => _rc.getInt(key);
  double getDouble(String key) => _rc.getDouble(key);
  bool getBool(String key) => _rc.getBool(key);
  String getString(String key) => _rc.getString(key);
}
