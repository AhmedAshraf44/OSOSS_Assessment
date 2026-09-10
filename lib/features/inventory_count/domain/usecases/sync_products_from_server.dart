import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';

class SyncProductsFromServer {
  const SyncProductsFromServer(this._repository);

  final ProductRepository _repository;

  Future<ApiResult<void>> call(int storeId) =>
      _repository.syncProductsFromServer(storeId);
}
