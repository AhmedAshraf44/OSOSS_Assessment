import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';

abstract interface class StoreRepository {
  Future<ApiResult<List<Store>>> getStores();

  /// Null when the employee hasn't picked a store yet on this device.
  Future<ApiResult<int?>> getSelectedStoreId();

  Future<ApiResult<void>> setSelectedStoreId(int storeId);
}
