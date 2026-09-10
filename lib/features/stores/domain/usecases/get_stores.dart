import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';
import 'package:inventory_count_app/features/stores/domain/repositories/store_repository.dart';

class GetStores {
  const GetStores(this._repository);

  final StoreRepository _repository;

  Future<ApiResult<List<Store>>> call() => _repository.getStores();
}
