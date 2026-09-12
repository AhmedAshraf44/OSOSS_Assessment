import 'package:inventory_count_app/features/inventory_count/data/models/submit_response_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/counted_item.dart';

/// Throws [NetworkException], [RequestTimeoutException],
/// [UnauthorizedException], [ServerException], or
/// [MalformedResponseException] on failure.
abstract interface class SessionRemoteDataSource {
  /// `POST /inventory-counts` with an `Idempotency-Key` header and a body
  /// of `{clientSessionId, storeId, createdAt, items}`.
  Future<SubmitResponseModel> submitCount({
    required String idempotencyKey,
    required String clientSessionId,
    required int storeId,
    required DateTime createdAt,
    required List<CountedItem> items,
  });
}
