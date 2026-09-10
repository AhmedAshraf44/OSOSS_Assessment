import 'package:inventory_count_app/features/inventory_count/data/models/submit_response_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/counted_item.dart';

/// Throws [NetworkException], [RequestTimeoutException],
/// [UnauthorizedException], [ServerException], or
/// [MalformedResponseException] on failure.
abstract interface class SessionRemoteDataSource {
  Future<SubmitResponseModel> submitCount({
    required String idempotencyKey,
    required int storeId,
    required List<CountedItem> items,
  });
}
