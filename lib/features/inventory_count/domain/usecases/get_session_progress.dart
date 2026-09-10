import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';

class GetSessionProgress {
  const GetSessionProgress(this._repository);

  final ProductRepository _repository;

  Future<ApiResult<CountProgress>> call({
    required int storeId,
    required String sessionId,
  }) {
    return _repository.getSessionProgress(
      storeId: storeId,
      sessionId: sessionId,
    );
  }
}
