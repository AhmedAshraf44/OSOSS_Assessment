import 'package:inventory_count_app/core/error/exception_mapper.dart';
import 'package:inventory_count_app/core/error/failures.dart';
import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/stores/data/datasources/store_local_data_source.dart';
import 'package:inventory_count_app/features/stores/data/datasources/store_remote_data_source.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';
import 'package:inventory_count_app/features/stores/domain/repositories/store_repository.dart';

class StoreRepositoryImpl implements StoreRepository {
  const StoreRepositoryImpl({
    required StoreRemoteDataSource remoteDataSource,
    required StoreLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final StoreRemoteDataSource _remoteDataSource;
  final StoreLocalDataSource _localDataSource;

  /// Downloads the stores and caches them; if the request fails, falls back
  /// to the last successful download so the app still opens offline and the
  /// employee can reach the products already on the device. The failure is
  /// only surfaced when there is no cache to fall back to.
  @override
  Future<ApiResult<List<Store>>> getStores() async {
    final remote = await guardApiCall(() async {
      final models = await _remoteDataSource.getStores();
      await _localDataSource.cacheStores(models);
      return models.map((model) => model.toEntity()).toList();
    });

    return switch (remote) {
      ResultSuccess<List<Store>>() => remote,
      ResultFailure<List<Store>>(:final failure) => _cachedStoresOr(failure),
    };
  }

  Future<ApiResult<List<Store>>> _cachedStoresOr(Failure failure) async {
    final cached = await guardApiCall(() async {
      final models = await _localDataSource.getCachedStores();
      return models.map((model) => model.toEntity()).toList();
    });

    return switch (cached) {
      ResultSuccess<List<Store>>(:final data) when data.isNotEmpty => cached,
      _ => ResultFailure(failure),
    };
  }

  @override
  Future<ApiResult<int?>> getSelectedStoreId() {
    return guardApiCall(() => _localDataSource.getSelectedStoreId());
  }

  @override
  Future<ApiResult<void>> setSelectedStoreId(int storeId) {
    return guardApiCall(() => _localDataSource.setSelectedStoreId(storeId));
  }
}
