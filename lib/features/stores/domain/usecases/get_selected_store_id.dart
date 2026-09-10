import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/stores/domain/repositories/store_repository.dart';

class GetSelectedStoreId {
  const GetSelectedStoreId(this._repository);

  final StoreRepository _repository;

  Future<ApiResult<int?>> call() => _repository.getSelectedStoreId();
}
