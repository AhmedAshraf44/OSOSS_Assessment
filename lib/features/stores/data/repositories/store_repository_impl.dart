import 'package:inventory_count_app/core/error/exception_mapper.dart';
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

  @override
  Future<ApiResult<List<Store>>> getStores() {
    return guardApiCall(() async {
      final models = await _remoteDataSource.getStores();
      return models.map((model) => model.toEntity()).toList();
    });
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
