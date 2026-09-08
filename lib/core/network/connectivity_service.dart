import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';


enum ConnectionQuality { offline, cellular, wifi }

/// Powers connectivity-aware UI states (§6 — Offline Resilience) and the Data
/// Saver decision for video (§6 — Bunny Stream cost control).

class ConnectivityService {
  ConnectivityService(this._connectivity) {
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      _controller.add(_map(results));
    });
  }

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _sub;
  final _controller = StreamController<ConnectionQuality>.broadcast();

  Stream<ConnectionQuality> get onChanged => _controller.stream;

  Future<ConnectionQuality> current() async =>
      _map(await _connectivity.checkConnectivity());

  Future<bool> get isOnline async =>
      (await current()) != ConnectionQuality.offline;

  ConnectionQuality _map(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return ConnectionQuality.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionQuality.cellular;
    }
    return ConnectionQuality.offline;
  }

  
  void dispose() {
    _sub.cancel();
    _controller.close();
  }
}
