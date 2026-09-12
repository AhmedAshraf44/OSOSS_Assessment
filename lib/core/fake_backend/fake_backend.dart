import 'package:inventory_count_app/core/fake_backend/fake_catalog.dart';
import 'package:inventory_count_app/core/fake_backend/fake_network_simulator.dart';
import 'package:inventory_count_app/core/fake_backend/fake_submission_processor.dart';
import 'package:inventory_count_app/core/network/connectivity_monitor.dart';

class FakeBackend {
  FakeBackend({ConnectivityMonitor? connectivityMonitor})
    : _network = FakeNetworkSimulator(connectivityMonitor: connectivityMonitor);

  final FakeCatalog _catalog = FakeCatalog();
  final FakeNetworkSimulator _network;
  late final FakeSubmissionProcessor _submissions = FakeSubmissionProcessor(
    _catalog,
  );

  set latency(Duration value) => _network.latency = value;
  set forceOffline(bool value) => _network.forceOffline = value;
  set forceServerError(bool value) => _network.forceServerError = value;
  set forceTimeout(bool value) => _network.forceTimeout = value;
  set forceUnauthorized(bool value) => _network.forceUnauthorized = value;

  Future<List<Map<String, dynamic>>> fetchStores() async {
    await _network.call();
    return _catalog.stores.map((store) => store.toJson()).toList();
  }

  /// `GET /stores/{storeId}/products?page=1&limit=50` ->
  /// `{ "data": [...], "page": 1, "totalPages": 10 }`.
  Future<Map<String, dynamic>> fetchProducts({
    required int storeId,
    required int page,
    int limit = 50,
  }) async {
    await _network.call();
    final result = _catalog.page(storeId: storeId, page: page, limit: limit);
    return {
      'data': result.items.map((product) => product.toJson()).toList(),
      'page': page,
      'totalPages': result.totalPages,
    };
  }

  /// `POST /inventory-counts` with header `Idempotency-Key: <key>` and a
  /// body of `{clientSessionId, storeId, createdAt, items}` ->
  /// `{ "sessionId": 9001, "status": "accepted" }` or
  /// `{ "status": "conflict", "conflicts": [...] }`.
  Future<Map<String, dynamic>> submitCount({
    required String idempotencyKey,
    required Map<String, dynamic> request,
  }) async {
    await _network.call();
    return _submissions.process(
      idempotencyKey: idempotencyKey,
      request: request,
    );
  }

  /// Debug/demo hook reproducing the documented conflict example: a sale
  /// reduces the server quantity and bumps the product's version.
  void simulateConcurrentSale({
    required int storeId,
    required int productId,
    int quantityDelta = -1,
  }) {
    _catalog.applySale(
      storeId: storeId,
      productId: productId,
      quantityDelta: quantityDelta,
    );
  }
}
