import 'package:connectivity_plus/connectivity_plus.dart';

/// Exposes the device's reported connectivity as a simple online/offline
/// signal.
///
/// This is intentionally NOT the source of truth for whether a sync will
/// succeed — a device can report "connected to Wi-Fi" while that network has
/// no real internet access, or sits behind a captive portal. It is one input
/// used to decide *when to attempt* a sync; the actual outcome always comes
/// from the request result itself (see SyncEngine), never from this signal
/// alone.
class ConnectivityMonitor {
  ConnectivityMonitor(this._connectivity);

  final Connectivity _connectivity;

  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  Future<bool> get isConnected async =>
      _hasConnection(await _connectivity.checkConnectivity());

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
