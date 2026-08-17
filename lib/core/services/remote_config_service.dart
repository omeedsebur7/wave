import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';
import 'package:wave/core/config/remote_config_keys.dart';

@lazySingleton
class RemoteConfigService {
  RemoteConfigService(this._rc);

  final FirebaseRemoteConfig _rc;

  Future<void> init() async {
    await _rc.setDefaults(RemoteConfigKeys.defaults);
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Short enough to react to a bad threshold quickly, long enough not to
        // hammer the service on every cold start.
        minimumFetchInterval: const Duration(minutes: 30),
      ),
    );
    await _rc.fetchAndActivate();
  }

  int getInt(String key) => _rc.getInt(key);
  double getDouble(String key) => _rc.getDouble(key);
  bool getBool(String key) => _rc.getBool(key);
  String getString(String key) => _rc.getString(key);
}
