import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/session_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/submit_response_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/counted_item.dart';

class FakeSessionRemoteDataSource implements SessionRemoteDataSource {
  const FakeSessionRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<SubmitResponseModel> submitCount({
    required String idempotencyKey,
    required String clientSessionId,
    required int storeId,
    required DateTime createdAt,
    required List<CountedItem> items,
  }) async {
    final json = await _backend.submitCount(
      idempotencyKey: idempotencyKey,
      request: {
        'clientSessionId': clientSessionId,
        'storeId': storeId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'items': items
            .map(
              (item) => {
                'productId': item.productId,
                'countedQuantity': item.countedQuantity,
                'expectedVersion': item.expectedVersion,
              },
            )
            .toList(),
      },
    );
    return SubmitResponseModel.fromJson(json);
  }
}
