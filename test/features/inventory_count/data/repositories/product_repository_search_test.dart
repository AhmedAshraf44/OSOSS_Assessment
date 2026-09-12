import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/fake_product_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/product_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_product_local_data_source.dart';

import '../../../../support/test_app_database.dart';

/// Exercises the real production flow end to end (FakeBackend -> remote
/// data source -> repository sync -> local search), not a hand-picked
/// fixture, so a regression in the sync-then-search path is caught here
/// independently of the presentation layer.
void main() {
  test('searching after a real catalog sync finds the documented example product', () async {
    final backend = FakeBackend()..latency = Duration.zero;
    final remote = FakeProductRemoteDataSource(backend);
    final local = SqfliteProductLocalDataSource(await createTestAppDatabase());
    final repository = ProductRepositoryImpl(remoteDataSource: remote, localDataSource: local);

    final syncResult = await repository.syncProductsFromServer(1);
    expect(syncResult.isSuccess, isTrue, reason: 'catalog sync should succeed');

    for (final query in ['Wireless', 'SCN-101', '6221234567890', 'wireless barcode']) {
      final pageResult = await repository.getLocalProductPage(
        storeId: 1,
        sessionId: 'diagnostic-session',
        offset: 0,
        limit: 50,
        searchQuery: query,
      );
      final page = pageResult.when(onSuccess: (p) => p, onFailure: (f) => null);
      expect(page, isNotNull, reason: 'query "$query" should not fail');
      expect(
        page!.entries.map((e) => e.product.name),
        contains('Wireless Barcode Scanner'),
        reason: 'query "$query" should find the seeded example product',
      );
    }
  });
}
