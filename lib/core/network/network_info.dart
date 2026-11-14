import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

typedef InternetProbe = Future<bool> Function();

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  final InternetProbe? _internetProbe;
  Future<bool>? _probeInFlight;
  DateTime? _lastProbeAt;
  bool? _lastProbeResult;

  NetworkInfoImpl(this._connectivity, {InternetProbe? internetProbe})
    : _internetProbe = internetProbe;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) return false;
    return _checkInternet();
  }

  Future<bool> _checkInternet() {
    final probe = _internetProbe;
    if (probe == null) return Future.value(true);

    final cachedAt = _lastProbeAt;
    final cachedResult = _lastProbeResult;
    if (cachedAt != null &&
        cachedResult != null &&
        DateTime.now().difference(cachedAt) <
            Duration(seconds: cachedResult ? 20 : 5)) {
      return Future.value(cachedResult);
    }

    return _probeInFlight ??= _runProbe(probe);
  }

  Future<bool> _runProbe(InternetProbe probe) async {
    var reachable = false;
    try {
      reachable = await probe().timeout(const Duration(seconds: 4));
    } catch (_) {
      reachable = false;
    }
    _lastProbeAt = DateTime.now();
    _lastProbeResult = reachable;
    _probeInFlight = null;
    return reachable;
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return Stream<bool>.multi((controller) {
      Future<void> publishStatus() async {
        try {
          final connected = await isConnected;
          if (!controller.isClosed) controller.add(connected);
        } catch (error, stackTrace) {
          if (!controller.isClosed) controller.addError(error, stackTrace);
        }
      }

      final subscription = _connectivity.onConnectivityChanged.listen((
        results,
      ) {
        if (results.contains(ConnectivityResult.none)) {
          controller.add(false);
        } else {
          unawaited(publishStatus());
        }
      }, onError: controller.addError);
      final retryTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(publishStatus()),
      );

      controller.onCancel = () async {
        retryTimer.cancel();
        await subscription.cancel();
      };
    }).distinct();
  }
}
