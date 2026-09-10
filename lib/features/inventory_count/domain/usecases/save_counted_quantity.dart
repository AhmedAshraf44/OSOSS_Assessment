import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';

class SaveCountedQuantity {
  const SaveCountedQuantity(this._repository);

  final ProductRepository _repository;

  Future<ApiResult<void>> call({
    required String sessionId,
    required int storeId,
    required int productId,
    required int? countedQuantity,
  }) {
    return _repository.saveCountedQuantity(
      sessionId: sessionId,
      storeId: storeId,
      productId: productId,
      countedQuantity: countedQuantity,
    );
  }
}
