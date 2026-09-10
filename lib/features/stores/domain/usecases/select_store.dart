import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/stores/domain/repositories/store_repository.dart';

class SelectStore {
  const SelectStore(this._repository);

  final StoreRepository _repository;

  Future<ApiResult<void>> call(int storeId) =>
      _repository.setSelectedStoreId(storeId);
}
