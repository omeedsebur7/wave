import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wave/core/config/remote_config_keys.dart';
import 'package:wave/core/services/remote_config_service.dart';

/// Force-update gate (§6). Remote Config holds the minimum supported build; a
/// client below it gets a blocking screen instead of running against an API
/// contract it no longer understands.
@lazySingleton
class ForceUpdateService {
  ForceUpdateService(this._rc);

  final RemoteConfigService _rc;

  Future<bool> isUpdateRequired() async {
    final info = await PackageInfo.fromPlatform();
    final current = int.tryParse(info.buildNumber) ?? 0;
    final minimum = _rc.getInt(RemoteConfigKeys.minSupportedBuild);
    return current < minimum;
  }

  String updateUrl({required bool isIos}) => _rc.getString(
        isIos
            ? RemoteConfigKeys.updateUrlIos
            : RemoteConfigKeys.updateUrlAndroid,
      );
}
