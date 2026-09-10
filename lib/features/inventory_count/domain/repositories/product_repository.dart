import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/counted_item.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_page.dart';

abstract interface class ProductRepository {
  /// Fetches every remote page for [storeId] and upserts each into local
  /// storage. The product list screen never calls this directly — it
  /// always renders from [getLocalProductPage].
  Future<ApiResult<void>> syncProductsFromServer(int storeId);

  /// Local-only, paginated, searchable, filterable read. Never touches the
  /// network, so previously-downloaded products stay accessible offline
  /// and the screen's memory footprint stays bounded regardless of catalog
  /// size.
  Future<ApiResult<ProductListPage>> getLocalProductPage({
    required int storeId,
    required String sessionId,
    required int offset,
    required int limit,
    String? searchQuery,
    ProductCountFilter filter = ProductCountFilter.all,
  });

  /// Saves (or, when [countedQuantity] is null, clears) the counted
  /// quantity for one product in one session. The expected version used
  /// for later conflict detection is snapshotted from the locally cached
  /// product at the moment of this call — never re-read at submit time.
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
  /// payload. Items with no counted quantity are excluded.
  Future<ApiResult<List<CountedItem>>> getCountedItems(String sessionId);
}
