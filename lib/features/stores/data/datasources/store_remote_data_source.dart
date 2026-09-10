import 'package:inventory_count_app/features/stores/data/models/store_model.dart';

/// Throws [NetworkException], [RequestTimeoutException], [ServerException],
/// or [MalformedResponseException] on failure (see core/error/exceptions.dart).
abstract interface class StoreRemoteDataSource {
  Future<List<StoreModel>> getStores();
}
