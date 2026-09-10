import 'dart:math';

import 'package:inventory_count_app/core/error/exceptions.dart';

/// A single in-memory, in-process stand-in for the real backend described
/// in the assessment's API contract — the "repository-based simulation"
/// option the task explicitly allows in place of a real server.
///
/// Registered as one lazy singleton in [configureDependencies] so every
/// feature's Fake*RemoteDataSource shares the same simulated dataset (a
/// store picked here is the same store products/sync will see later).
///
/// Debug knobs ([forceOffline], [forceServerError], [forceTimeout],
/// [forceUnauthorized]) let a developer menu reproduce the error scenarios
/// from the assessment on demand instead of only by chance.
/// [simulateConcurrentSale] reproduces the assessment's documented
/// version-conflict scenario on demand.
class FakeBackend {
  FakeBackend({Random? random}) : _random = random ?? Random() {
    _productsByStore = {
      for (final store in _stores) store.id: _seedProducts(store.id),
    };
  }

  // ignore: unused_field
  final Random _random;

  Duration latency = const Duration(milliseconds: 500);

  /// Simulates "no internet connection" on every call.
  bool forceOffline = false;

  /// Simulates a backend outage (HTTP 500) distinct from a connectivity
  /// problem — used to prove the app handles real request failures, not
  /// just the device's reported connectivity state.
  bool forceServerError = false;

  /// Simulates a request that never comes back in time.
  bool forceTimeout = false;

  /// Simulates an expired/invalid session.
  bool forceUnauthorized = false;

  final List<_StoreRecord> _stores = [
    _StoreRecord(id: 1, name: 'Cairo Store'),
    _StoreRecord(id: 2, name: 'Alexandria Store'),
    _StoreRecord(id: 3, name: 'Giza Store'),
  ];

  late final Map<int, List<_ProductRecord>> _productsByStore;

  /// Idempotency-Key -> previously computed response. Replaying the same
  /// key returns the exact same result without re-processing the
  /// submission or allocating a new server session id — this is what
  /// makes retries safe.
  final Map<String, Map<String, dynamic>> _idempotencyResults = {};

  int _nextServerSessionId = 9001;

  Future<List<Map<String, dynamic>>> fetchStores() async {
    await _simulateNetwork();
    return _stores.map((s) => {'id': s.id, 'name': s.name}).toList();
  }

  /// Matches the assessment's documented contract:
  /// `GET /stores/{storeId}/products?page=1&limit=50` ->
  /// `{ "data": [...], "page": 1, "totalPages": 10 }`.
  Future<Map<String, dynamic>> fetchProducts({
    required int storeId,
    required int page,
    int limit = 50,
  }) async {
    await _simulateNetwork();

    final all = _productsByStore[storeId] ?? const <_ProductRecord>[];
    final totalPages = all.isEmpty ? 1 : (all.length / limit).ceil();
    final start = (page - 1) * limit;
    final end = (start + limit).clamp(0, all.length);
    final pageItems = start >= all.length
        ? const <_ProductRecord>[]
        : all.sublist(start, end);

    return {
      'data': pageItems.map((p) => p.toJson()).toList(),
      'page': page,
      'totalPages': totalPages,
    };
  }

  /// Matches the assessment's documented contract:
  /// `POST /inventory-counts` with header `Idempotency-Key: <key>` ->
  /// `{ "sessionId": 9001, "status": "accepted" }` or
  /// `{ "status": "conflict", "conflicts": [...] }`.
  ///
  /// Replaying the same [idempotencyKey] (a retry of the same client
  /// session) returns the cached result instead of processing the
  /// submission again — no duplicate server session is ever created.
  Future<Map<String, dynamic>> submitCount({
    required String idempotencyKey,
    required int storeId,
    required List<Map<String, dynamic>> items,
  }) async {
    await _simulateNetwork();

    final cached = _idempotencyResults[idempotencyKey];
    if (cached != null) return cached;

    final products = _productsByStore[storeId] ?? const <_ProductRecord>[];
    final conflicts = <Map<String, dynamic>>[];

    for (final item in items) {
      final productId = item['productId'] as int;
      final expectedVersion = item['expectedVersion'] as int;
      final product = _findProduct(products, productId);
      if (product == null) continue;

      if (product.version != expectedVersion) {
        conflicts.add({
          'productId': productId,
          'expectedVersion': expectedVersion,
          'currentVersion': product.version,
          'originalSystemQuantity':
              product.versionHistory[expectedVersion] ?? product.systemQuantity,
          'currentSystemQuantity': product.systemQuantity,
          'countedQuantity': item['countedQuantity'],
        });
      }
    }

    final Map<String, dynamic> result;
    if (conflicts.isNotEmpty) {
      result = {'status': 'conflict', 'conflicts': conflicts};
    } else {
      result = {'sessionId': _nextServerSessionId++, 'status': 'accepted'};
    }

    _idempotencyResults[idempotencyKey] = result;
    return result;
  }

  /// Debug/demo hook: simulates a sale reducing stock and bumping the
  /// product's version — reproduces the assessment's documented conflict
  /// example ("a sale reduces the server quantity to 19 and changes the
  /// inventory version to 6") on demand instead of only by chance.
  void simulateConcurrentSale({
    required int storeId,
    required int productId,
    int quantityDelta = -1,
  }) {
    final products = _productsByStore[storeId];
    if (products == null) return;
    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    final current = products[index];
    // Remember what the system quantity was at the version being replaced,
    // so a later conflict response can report the employee's original
    // systemQuantity alongside the new one.
    current.versionHistory[current.version] = current.systemQuantity;

    products[index] = _ProductRecord(
      id: current.id,
      name: current.name,
      sku: current.sku,
      barcode: current.barcode,
      systemQuantity: (current.systemQuantity + quantityDelta).clamp(0, 1 << 30),
      version: current.version + 1,
      updatedAt: DateTime.now(),
      versionHistory: current.versionHistory,
    );
  }

  _ProductRecord? _findProduct(List<_ProductRecord> products, int productId) {
    for (final product in products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Future<void> _simulateNetwork() async {
    await Future<void>.delayed(latency);
    if (forceOffline) throw const NetworkException();
    if (forceTimeout) throw const RequestTimeoutException();
    if (forceUnauthorized) throw const UnauthorizedException();
    if (forceServerError) throw const ServerException(500);
  }

  static List<_ProductRecord> _seedProducts(int storeId) {
    const categories = [
      'Scanner',
      'Printer',
      'Cable',
      'Adapter',
      'Battery',
      'Charger',
      'Case',
      'Stand',
      'Mount',
      'Sensor',
    ];
    const countPerStore = 137;
    final baseId = storeId * 1000 + 100;
    final now = DateTime.now();

    final products = List.generate(countPerStore, (i) {
      final id = baseId + i;
      final category = categories[i % categories.length];
      return _ProductRecord(
        id: id,
        name: '$category Model ${_labelFor(i)}',
        sku: 'SKU-$id',
        barcode: '622${id.toString().padLeft(10, '0')}',
        systemQuantity: 5 + (i * 7) % 95,
        version: 1 + (i % 5),
        updatedAt: now.subtract(Duration(hours: i)),
      );
    });

    // Store 1's first item mirrors the assessment's documented example
    // product exactly (SKU-101, version 5, systemQuantity 20) so the
    // conflict demo lines up with the PDF's worked example.
    if (storeId == 1) {
      products[0] = _ProductRecord(
        id: 101,
        name: 'Wireless Barcode Scanner',
        sku: 'SKU-101',
        barcode: '6221234567890',
        systemQuantity: 20,
        version: 5,
        updatedAt: DateTime.parse('2026-09-06T10:00:00Z'),
      );
    }

    return products;
  }

  static String _labelFor(int index) {
    final letter = String.fromCharCode(65 + (index ~/ 10) % 26);
    return '$letter${index % 10}';
  }
}

class _StoreRecord {
  _StoreRecord({required this.id, required this.name});
  final int id;
  final String name;
}

class _ProductRecord {
  _ProductRecord({
    required this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.systemQuantity,
    required this.version,
    required this.updatedAt,
    Map<int, int>? versionHistory,
  }) : versionHistory = versionHistory ?? {};

  final int id;
  final String name;
  final String sku;
  final String barcode;
  final int systemQuantity;
  final int version;
  final DateTime updatedAt;

  /// version -> systemQuantity at that version, recorded whenever
  /// [FakeBackend.simulateConcurrentSale] bumps the version.
  final Map<int, int> versionHistory;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'barcode': barcode,
    'systemQuantity': systemQuantity,
    'version': version,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
