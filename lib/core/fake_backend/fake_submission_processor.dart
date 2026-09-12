import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/core/fake_backend/fake_catalog.dart';

/// Server side of `POST /inventory-counts`: request validation,
/// version-conflict detection, and idempotency-key deduplication.
///
/// Replaying an accepted key returns the cached response instead of
/// processing the submission again — no retry ever creates a duplicate
/// server session.
class FakeSubmissionProcessor {
  FakeSubmissionProcessor(this._catalog);

  final FakeCatalog _catalog;
  final Map<String, Map<String, dynamic>> _acceptedByIdempotencyKey = {};

  int _nextServerSessionId = 9001;

  /// [request] is the documented body:
  /// `{clientSessionId, storeId, createdAt, items}`.
  Map<String, dynamic> process({
    required String idempotencyKey,
    required Map<String, dynamic> request,
  }) {
    final (storeId, items) = _parse(idempotencyKey, request);

    final cached = _acceptedByIdempotencyKey[idempotencyKey];
    if (cached != null) return cached;

    final conflicts = _detectConflicts(storeId, items);

    // A conflict stores nothing server-side, so there is no write to
    // deduplicate — and caching it would pin the session to that answer
    // forever, making conflict resolution impossible. Only an accepted
    // submission is replayed from the cache.
    if (conflicts.isNotEmpty) {
      return {'status': 'conflict', 'conflicts': conflicts};
    }

    final result = {'sessionId': _nextServerSessionId++, 'status': 'accepted'};
    _acceptedByIdempotencyKey[idempotencyKey] = result;
    return result;
  }

  /// Rejects a request missing any field the contract requires, the way a
  /// real endpoint would, instead of silently accepting a partial body.
  (int, List<Map<String, dynamic>>) _parse(
    String idempotencyKey,
    Map<String, dynamic> request,
  ) {
    final clientSessionId = request['clientSessionId'];
    final storeId = request['storeId'];
    final createdAt = request['createdAt'];
    final items = request['items'];

    if (idempotencyKey.isEmpty ||
        clientSessionId is! String ||
        clientSessionId.isEmpty ||
        storeId is! int ||
        createdAt is! String ||
        DateTime.tryParse(createdAt) == null ||
        items is! List) {
      throw const ServerException(400, 'Malformed inventory-count request.');
    }

    return (storeId, items.cast<Map<String, dynamic>>());
  }

  List<Map<String, dynamic>> _detectConflicts(
    int storeId,
    List<Map<String, dynamic>> items,
  ) {
    final conflicts = <Map<String, dynamic>>[];

    for (final item in items) {
      final productId = item['productId'] as int;
      final expectedVersion = item['expectedVersion'] as int;
      final product = _catalog.findProduct(storeId, productId);

      if (product == null || product.version == expectedVersion) continue;

      conflicts.add({
        'productId': productId,
        'expectedVersion': expectedVersion,
        'currentVersion': product.version,
        'originalSystemQuantity': product.quantityAt(expectedVersion),
        'currentSystemQuantity': product.systemQuantity,
        'countedQuantity': item['countedQuantity'],
      });
    }

    return conflicts;
  }
}
