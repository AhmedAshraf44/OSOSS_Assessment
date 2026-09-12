import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/core/network/connectivity_monitor.dart';

/// Stands in for the wire between the app and the simulated backend.
///
/// Every "request" is really an in-process call, so without this the
/// device's Wi-Fi state would have no effect at all. [connectivityMonitor]
/// closes that gap; the force* knobs reproduce the assessment's error
/// scenarios on demand instead of only by chance.
class FakeNetworkSimulator {
  FakeNetworkSimulator({ConnectivityMonitor? connectivityMonitor})
    : _connectivityMonitor = connectivityMonitor;

  final ConnectivityMonitor? _connectivityMonitor;

  Duration latency = const Duration(milliseconds: 500);
  bool forceOffline = false;
  bool forceServerError = false;
  bool forceTimeout = false;
  bool forceUnauthorized = false;

  Future<void> call() async {
    await Future<void>.delayed(latency);
    _throwForcedFailure();

    final monitor = _connectivityMonitor;
    if (monitor != null && !(await monitor.isConnected)) {
      throw const NetworkException();
    }
  }

  void _throwForcedFailure() {
    if (forceOffline) throw const NetworkException();
    if (forceTimeout) throw const RequestTimeoutException();
    if (forceUnauthorized) throw const UnauthorizedException();
    if (forceServerError) throw const ServerException(500);
  }
}
