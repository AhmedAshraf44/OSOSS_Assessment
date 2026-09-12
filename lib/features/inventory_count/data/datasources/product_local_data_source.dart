import 'package:inventory_count_app/features/inventory_count/data/models/product_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';

/// Throws [LocalStorageException] on failure.
abstract interface class ProductLocalDataSource {
  Future<void> upsertProducts(int storeId, List<ProductModel> products);

  /// Rows from `products LEFT JOIN count_items`, each carrying a
  /// `counted_quantity` column — see [ProductModel.entryFromRow].
  Future<List<Map<String, Object?>>> queryPage({
    required int storeId,
    required String sessionId,
    required int offset,
    required int limit,
    String? searchQuery,
    ProductCountFilter filter = ProductCountFilter.all,
  });

  Future<void> upsertCountedQuantity({
    required String sessionId,
    required int productId,
    required int expectedVersion,
    required int countedQuantity,
  });

  Future<void> clearCountedQuantity({
    required String sessionId,
    required int productId,
  });

  /// The version currently cached locally for this product, or null if the
  /// product hasn't been synced from the server yet.
  Future<int?> getProductVersion({required int storeId, required int productId});

  /// `{'total': ..., 'counted': ...}` across every product for [storeId],
  /// regardless of any list search/filter in effect.
  Future<Map<String, int>> getProgress({
    required int storeId,
    required String sessionId,
  });

  /// Rows from `count_items` for [sessionId] where a quantity was actually
  /// entered — the submission payload's source.
  Future<List<Map<String, Object?>>> getCountedItemRows(String sessionId);

  /// Cached product rows matching [productIds] — used to show a clearly
  /// identified product (name, SKU) alongside a conflict.
  Future<List<Map<String, Object?>>> getProductRowsByIds({
    required int storeId,
    required List<int> productIds,
  });

  /// How many products are cached for [storeId] — the denominator of every
  /// session's progress.
  Future<int> getProductCount(int storeId);

  /// sessionId -> number of products counted in it, for all sessions at
  /// once (one query instead of one per session).
  Future<Map<String, int>> getCountedTotalsBySession(List<String> sessionIds);
}
