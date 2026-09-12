import 'package:sqflite/sqflite.dart';

import 'package:inventory_count_app/core/db/app_database.dart';
import 'package:inventory_count_app/core/db/db_tables.dart';
import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';

class SqfliteProductLocalDataSource implements ProductLocalDataSource {
  const SqfliteProductLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<void> upsertProducts(int storeId, List<ProductModel> products) async {
    try {
      final db = await _appDatabase.database;
      final batch = db.batch();
      for (final product in products) {
        batch.insert(
          DbTables.products,
          product.toDbMap(storeId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {
      throw const LocalStorageException('Could not save products locally.');
    }
  }

  @override
  Future<List<Map<String, Object?>>> queryPage({
    required int storeId,
    required String sessionId,
    required int offset,
    required int limit,
    String? searchQuery,
    ProductCountFilter filter = ProductCountFilter.all,
  }) async {
    try {
      final db = await _appDatabase.database;
      final (where, args) = _buildWhere(storeId, searchQuery, filter);

      return db.rawQuery('''
        SELECT
          p.*,
          ci.counted_quantity AS counted_quantity,
          sc.product_id IS NOT NULL AS has_conflict
        FROM ${DbTables.products} p
        LEFT JOIN ${DbTables.countItems} ci
          ON ci.session_id = ? AND ci.product_id = p.id
        LEFT JOIN ${DbTables.syncConflicts} sc
          ON sc.session_id = ? AND sc.product_id = p.id
        WHERE $where
        ORDER BY p.name ASC
        LIMIT ? OFFSET ?
      ''', [sessionId, sessionId, ...args, limit, offset]);
    } catch (_) {
      throw const LocalStorageException('Could not read products locally.');
    }
  }

  @override
  Future<void> upsertCountedQuantity({
    required String sessionId,
    required int productId,
    required int expectedVersion,
    required int countedQuantity,
  }) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(DbTables.countItems, {
        'session_id': sessionId,
        'product_id': productId,
        'counted_quantity': countedQuantity,
        'expected_version': expectedVersion,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      throw const LocalStorageException('Could not save the counted quantity.');
    }
  }

  @override
  Future<void> clearCountedQuantity({
    required String sessionId,
    required int productId,
  }) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        DbTables.countItems,
        where: 'session_id = ? AND product_id = ?',
        whereArgs: [sessionId, productId],
      );
    } catch (_) {
      throw const LocalStorageException('Could not clear the counted quantity.');
    }
  }

  @override
  Future<int?> getProductVersion({
    required int storeId,
    required int productId,
  }) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbTables.products,
        columns: ['version'],
        where: 'store_id = ? AND id = ?',
        whereArgs: [storeId, productId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return rows.first['version'] as int?;
    } catch (_) {
      throw const LocalStorageException('Could not read the product version.');
    }
  }

  @override
  Future<Map<String, int>> getProgress({
    required int storeId,
    required String sessionId,
  }) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.rawQuery(
        '''
        SELECT
          COUNT(*) AS total,
          SUM(CASE WHEN ci.counted_quantity IS NOT NULL THEN 1 ELSE 0 END) AS counted
        FROM ${DbTables.products} p
        LEFT JOIN ${DbTables.countItems} ci
          ON ci.session_id = ? AND ci.product_id = p.id
        WHERE p.store_id = ?
        ''',
        [sessionId, storeId],
      );
      final row = rows.first;
      return {
        'total': (row['total'] as int?) ?? 0,
        'counted': (row['counted'] as int?) ?? 0,
      };
    } catch (_) {
      throw const LocalStorageException('Could not compute count progress.');
    }
  }

  @override
  Future<List<Map<String, Object?>>> getCountedItemRows(String sessionId) async {
    try {
      final db = await _appDatabase.database;
      return db.query(
        DbTables.countItems,
        where: 'session_id = ? AND counted_quantity IS NOT NULL',
        whereArgs: [sessionId],
      );
    } catch (_) {
      throw const LocalStorageException('Could not read counted items.');
    }
  }

  @override
  Future<List<Map<String, Object?>>> getProductRowsByIds({
    required int storeId,
    required List<int> productIds,
  }) async {
    if (productIds.isEmpty) return const [];
    try {
      final db = await _appDatabase.database;
      final placeholders = List.filled(productIds.length, '?').join(', ');
      return db.rawQuery(
        'SELECT * FROM ${DbTables.products} WHERE store_id = ? AND id IN ($placeholders)',
        [storeId, ...productIds],
      );
    } catch (_) {
      throw const LocalStorageException('Could not read the products.');
    }
  }

  @override
  Future<int> getProductCount(int storeId) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS total FROM ${DbTables.products} WHERE store_id = ?',
        [storeId],
      );
      return (rows.first['total'] as int?) ?? 0;
    } catch (_) {
      throw const LocalStorageException('Could not count the products.');
    }
  }

  @override
  Future<Map<String, int>> getCountedTotalsBySession(
    List<String> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return const {};
    try {
      final db = await _appDatabase.database;
      final placeholders = List.filled(sessionIds.length, '?').join(', ');
      final rows = await db.rawQuery('''
        SELECT session_id, COUNT(*) AS counted
        FROM ${DbTables.countItems}
        WHERE counted_quantity IS NOT NULL AND session_id IN ($placeholders)
        GROUP BY session_id
      ''', sessionIds);

      return {
        for (final row in rows)
          row['session_id']! as String: (row['counted'] as int?) ?? 0,
      };
    } catch (_) {
      throw const LocalStorageException('Could not read session progress.');
    }
  }

  (String, List<Object?>) _buildWhere(
    int storeId,
    String? searchQuery,
    ProductCountFilter filter,
  ) {
    final where = StringBuffer('p.store_id = ?');
    final args = <Object?>[storeId];

    final trimmedQuery = searchQuery?.trim();
    if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
      final likeQuery = '%$trimmedQuery%';
      where.write(' AND (p.name LIKE ? OR p.sku LIKE ? OR p.barcode LIKE ?)');
      args.addAll([likeQuery, likeQuery, likeQuery]);
    }

    switch (filter) {
      case ProductCountFilter.counted:
        where.write(' AND ci.counted_quantity IS NOT NULL');
      case ProductCountFilter.notCounted:
        where.write(' AND ci.counted_quantity IS NULL');
      case ProductCountFilter.all:
        break;
    }

    return (where.toString(), args);
  }
}
