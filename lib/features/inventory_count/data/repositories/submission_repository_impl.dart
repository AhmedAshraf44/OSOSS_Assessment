import 'package:inventory_count_app/core/error/exception_mapper.dart';
import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/session_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/counted_item.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/submit_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/submission_repository.dart';

class SubmissionRepositoryImpl implements SubmissionRepository {
  const SubmissionRepositoryImpl({
    required SessionRemoteDataSource remoteDataSource,
    required ProductLocalDataSource productLocalDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _productLocalDataSource = productLocalDataSource;

  final SessionRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _productLocalDataSource;

  @override
  Future<ApiResult<SubmitResult>> submit(CountSession session) {
    return guardApiCall(() async {
      final rows = await _productLocalDataSource.getCountedItemRows(
        session.localId,
      );
      final items = rows
          .map(
            (row) => CountedItem(
              productId: row['product_id']! as int,
              countedQuantity: row['counted_quantity']! as int,
              expectedVersion: row['expected_version']! as int,
            ),
          )
          .toList();

      final response = await _remoteDataSource.submitCount(
        idempotencyKey: session.idempotencyKey,
        storeId: session.storeId,
        items: items,
      );
      return response.toEntity();
    });
  }
}
