import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/counted_item.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_page.dart';

abstract interface class ProductRepository {
  /// Fetches every remote page for [storeId] into local storage. The list
  /// screen never calls this directly — it renders from
  /// [getLocalProductPage].
  Future<ApiResult<void>> syncProductsFromServer(int storeId);

  /// Local-only, paginated, searchable, filterable read. Never touches the
  /// network, so downloaded products stay available offline and the
  /// screen's memory stays bounded regardless of catalog size.
  Future<ApiResult<ProductListPage>> getLocalProductPage({
    required int storeId,
    required String sessionId,
    required int offset,
    required int limit,
    String? searchQuery,
    ProductCountFilter filter = ProductCountFilter.all,
  });

  /// Saves (or clears, when [countedQuantity] is null) one product's count.
  /// The expected version used for conflict detection is snapshotted from
  /// the cached product at this moment — never re-read at submit time.
  Future<ApiResult<void>> saveCountedQuantity({
    required String sessionId,
    required int storeId,
    required int productId,
    required int? countedQuantity,
  });

  Future<ApiResult<CountProgress>> getSessionProgress({
    required int storeId,
    required String sessionId,
  });

  /// Every counted item for [sessionId], ready to build a submission
  /// payload. Uncounted products are excluded.
  Future<ApiResult<List<CountedItem>>> getCountedItems(String sessionId);

  /// Cached products matching [productIds], for naming a product alongside
  /// its conflict.
  Future<ApiResult<List<Product>>> getProductsByIds({
    required int storeId,
    required List<int> productIds,
  });

  /// Progress for several sessions at once, so the sessions list doesn't
  /// run one query per row.
  Future<ApiResult<Map<String, CountProgress>>> getProgressForSessions({
    required int storeId,
    required List<String> sessionIds,
  });
}
