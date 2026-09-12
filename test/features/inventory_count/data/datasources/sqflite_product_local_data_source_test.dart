import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/count_session_model.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_conflict_model.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';

import '../../../../support/test_app_database.dart';

void main() {
  late SqfliteProductLocalDataSource dataSource;
  late SqfliteCountSessionLocalDataSource sessionDataSource;

  setUp(() async {
    final appDatabase = await createTestAppDatabase();
    dataSource = SqfliteProductLocalDataSource(appDatabase);
    sessionDataSource = SqfliteCountSessionLocalDataSource(appDatabase);
  });

  ProductModel product(
    int id, {
    String? name,
    int systemQuantity = 10,
    int version = 1,
  }) {
    return ProductModel(
      id: id,
      name: name ?? 'Product $id',
      sku: 'SKU-$id',
      barcode: '000$id',
      systemQuantity: systemQuantity,
      version: version,
      updatedAt: DateTime.parse('2026-01-01T00:00:00Z'),
    );
  }

  group('upsertProducts + queryPage', () {
    test('paginates results in name order', () async {
      await dataSource.upsertProducts(1, [
        product(3, name: 'Charlie'),
        product(1, name: 'Alpha'),
        product(2, name: 'Bravo'),
      ]);

      final firstPage = await dataSource.queryPage(
        storeId: 1,
        sessionId: 's1',
        offset: 0,
        limit: 2,
      );
      expect(firstPage.map((r) => r['name']), ['Alpha', 'Bravo']);

      final secondPage = await dataSource.queryPage(
        storeId: 1,
        sessionId: 's1',
        offset: 2,
        limit: 2,
      );
      expect(secondPage.map((r) => r['name']), ['Charlie']);
    });

    test('scopes results to one store — data never mixes across stores', () async {
      await dataSource.upsertProducts(1, [product(1, name: 'Store1 Product')]);
      // Same product id, different store: must not collide or leak across.
      await dataSource.upsertProducts(2, [product(1, name: 'Store2 Product')]);

      final store1Rows = await dataSource.queryPage(
        storeId: 1,
        sessionId: 's1',
        offset: 0,
        limit: 10,
      );
      expect(store1Rows, hasLength(1));
      expect(store1Rows.single['name'], 'Store1 Product');
    });

    test('searches by name, sku, or barcode', () async {
      await dataSource.upsertProducts(1, [
        product(1, name: 'Wireless Scanner'),
        product(2, name: 'Cable'),
      ]);

      final results = await dataSource.queryPage(
        storeId: 1,
        sessionId: 's1',
        offset: 0,
        limit: 10,
        searchQuery: 'scanner',
      );
      expect(results, hasLength(1));
      expect(results.single['name'], 'Wireless Scanner');
    });

    test('re-upserting the same product id replaces it instead of duplicating', () async {
      await dataSource.upsertProducts(1, [
        product(1, name: 'Old Name', systemQuantity: 5),
      ]);
      await dataSource.upsertProducts(1, [
        product(1, name: 'New Name', systemQuantity: 9),
      ]);

      final rows = await dataSource.queryPage(
        storeId: 1,
        sessionId: 's1',
        offset: 0,
        limit: 10,
      );
      expect(rows, hasLength(1));
      expect(rows.single['name'], 'New Name');
      expect(rows.single['system_quantity'], 9);
    });
  });

  group('counted quantity + progress', () {
    test('a saved counted quantity shows up in queryPage and getProgress', () async {
      await dataSource.upsertProducts(1, [product(1), product(2)]);

      await dataSource.upsertCountedQuantity(
        sessionId: 's1',
        productId: 1,
        expectedVersion: 1,
        countedQuantity: 8,
      );

      final rows = await dataSource.queryPage(
        storeId: 1,
        sessionId: 's1',
        offset: 0,
        limit: 10,
      );
      final countedRow = rows.firstWhere((r) => r['id'] == 1);
      expect(countedRow['counted_quantity'], 8);

      final progress = await dataSource.getProgress(storeId: 1, sessionId: 's1');
      expect(progress['total'], 2);
      expect(progress['counted'], 1);
    });

    test('clearCountedQuantity returns the product to not-counted', () async {
      await dataSource.upsertProducts(1, [product(1)]);
      await dataSource.upsertCountedQuantity(
        sessionId: 's1',
        productId: 1,
        expectedVersion: 1,
        countedQuantity: 8,
      );

      await dataSource.clearCountedQuantity(sessionId: 's1', productId: 1);

      final progress = await dataSource.getProgress(storeId: 1, sessionId: 's1');
      expect(progress['counted'], 0);
    });

    test('filter=counted / notCounted only returns matching rows', () async {
      await dataSource.upsertProducts(1, [
        product(1, name: 'A'),
        product(2, name: 'B'),
      ]);
      await dataSource.upsertCountedQuantity(
        sessionId: 's1',
        productId: 1,
        expectedVersion: 1,
        countedQuantity: 3,
      );

      final counted = await dataSource.queryPage(
        storeId: 1,
        sessionId: 's1',
        offset: 0,
        limit: 10,
        filter: ProductCountFilter.counted,
      );
      expect(counted.map((r) => r['id']), [1]);

      final notCounted = await dataSource.queryPage(
        storeId: 1,
        sessionId: 's1',
        offset: 0,
        limit: 10,
        filter: ProductCountFilter.notCounted,
      );
      expect(notCounted.map((r) => r['id']), [2]);
    });

    test('getCountedItemRows only returns items with a non-null quantity', () async {
      await dataSource.upsertProducts(1, [product(1), product(2)]);
      await dataSource.upsertCountedQuantity(
        sessionId: 's1',
        productId: 1,
        expectedVersion: 1,
        countedQuantity: 4,
      );

      final rows = await dataSource.getCountedItemRows('s1');
      expect(rows, hasLength(1));
      expect(rows.single['product_id'], 1);
    });
  });

  group('queryPage conflict flag', () {
    test(
      'flags only the products the server reported a version conflict for',
      () async {
        await dataSource.upsertProducts(1, [
          product(1, name: 'Conflicted', version: 5),
          product(2, name: 'Clean', version: 1),
        ]);
        await sessionDataSource.insertSession(
          CountSessionModel.newDraft(
            localId: 's1',
            storeId: 1,
            employeeId: 'emp-1',
            idempotencyKey: 'key-1',
          ),
        );
        await sessionDataSource.markConflict('s1', const [
          ProductConflictModel(
            productId: 1,
            expectedVersion: 5,
            currentVersion: 6,
            originalSystemQuantity: 10,
            currentSystemQuantity: 9,
            countedQuantity: 8,
          ),
        ]);

        final rows = await dataSource.queryPage(
          storeId: 1,
          sessionId: 's1',
          offset: 0,
          limit: 10,
        );

        final byName = {for (final row in rows) row['name']: row};
        expect(byName['Conflicted']!['has_conflict'], 1);
        expect(byName['Clean']!['has_conflict'], 0);
      },
    );
  });

  group('getProductRowsByIds', () {
    test('returns only the requested, store-scoped products', () async {
      await dataSource.upsertProducts(1, [
        product(1, name: 'A'),
        product(2, name: 'B'),
        product(3, name: 'C'),
      ]);

      final rows = await dataSource.getProductRowsByIds(
        storeId: 1,
        productIds: [1, 3],
      );
      expect(rows, hasLength(2));
      expect(rows.map((r) => r['name']), containsAll(['A', 'C']));
    });
  });
}
