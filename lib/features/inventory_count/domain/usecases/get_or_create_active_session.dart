import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';

class GetOrCreateActiveSession {
  const GetOrCreateActiveSession(this._repository);

  final CountSessionRepository _repository;

  Future<ApiResult<CountSession>> call(int storeId) =>
      _repository.getOrCreateActiveSession(storeId);
}
