import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_remote_data_source.dart';

/// Pulls a store's catalog page by page and upserts each page locally, so
/// the list screen can always render from local storage.
class ProductCatalogSynchronizer {
  const ProductCatalogSynchronizer({
    required ProductRemoteDataSource remoteDataSource,
    required ProductLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;

  Future<void> syncStore(int storeId) async {
    var page = 1;

    while (true) {
      final response = await _remoteDataSource.getProducts(
        storeId: storeId,
        page: page,
      );
      await _localDataSource.upsertProducts(storeId, response.data);

      if (page >= response.totalPages) return;
      page++;
    }
  }
}
