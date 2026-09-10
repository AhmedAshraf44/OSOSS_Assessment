import 'package:inventory_count_app/core/error/exception_mapper.dart';
import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/counted_item.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_page.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
    required ProductLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;

  @override
  Future<ApiResult<void>> syncProductsFromServer(int storeId) {
    return guardApiCall(() async {
      var page = 1;
      while (true) {
        final response = await _remoteDataSource.getProducts(
          storeId: storeId,
          page: page,
        );
        await _localDataSource.upsertProducts(storeId, response.data);
        if (page >= response.totalPages) break;
        page++;
      }
    });
  }

  @override
  Future<ApiResult<ProductListPage>> getLocalProductPage({
    required int storeId,
    required String sessionId,
    required int offset,
    required int limit,
    String? searchQuery,
    ProductCountFilter filter = ProductCountFilter.all,
  }) {
    return guardApiCall(() async {
      // Fetch one extra row to detect whether another page exists without a
      // separate COUNT(*) round trip.
      final rows = await _localDataSource.queryPage(
        storeId: storeId,
        sessionId: sessionId,
        offset: offset,
        limit: limit + 1,
        searchQuery: searchQuery,
        filter: filter,
      );
      final hasMore = rows.length > limit;
      final pageRows = hasMore ? rows.sublist(0, limit) : rows;
      return ProductListPage(
        entries: pageRows.map(ProductModel.entryFromRow).toList(),
        hasMore: hasMore,
      );
    });
  }

  @override
  Future<ApiResult<void>> saveCountedQuantity({
    required String sessionId,
    required int storeId,
    required int productId,
    required int? countedQuantity,
  }) {
    return guardApiCall(() async {
      if (countedQuantity == null) {
        await _localDataSource.clearCountedQuantity(
          sessionId: sessionId,
          productId: productId,
        );
        return;
      }

      final currentVersion = await _localDataSource.getProductVersion(
        storeId: storeId,
        productId: productId,
      );
      if (currentVersion == null) {
        throw const LocalStorageException('Product not found locally.');
      }

      await _localDataSource.upsertCountedQuantity(
        sessionId: sessionId,
        productId: productId,
        expectedVersion: currentVersion,
        countedQuantity: countedQuantity,
      );
    });
  }

  @override
  Future<ApiResult<CountProgress>> getSessionProgress({
    required int storeId,
    required String sessionId,
  }) {
    return guardApiCall(() async {
      final result = await _localDataSource.getProgress(
        storeId: storeId,
        sessionId: sessionId,
      );
      return CountProgress(
        counted: result['counted'] ?? 0,
        total: result['total'] ?? 0,
      );
    });
  }

  @override
  Future<ApiResult<List<CountedItem>>> getCountedItems(String sessionId) {
    return guardApiCall(() async {
      final rows = await _localDataSource.getCountedItemRows(sessionId);
      return rows
          .map(
            (row) => CountedItem(
              productId: row['product_id']! as int,
              countedQuantity: row['counted_quantity']! as int,
              expectedVersion: row['expected_version']! as int,
            ),
          )
          .toList();
    });
  }
}
