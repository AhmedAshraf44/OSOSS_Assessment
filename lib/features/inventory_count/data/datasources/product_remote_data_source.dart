import 'package:inventory_count_app/features/inventory_count/data/models/product_page_response_model.dart';

/// Throws [NetworkException], [RequestTimeoutException], [ServerException],
/// or [MalformedResponseException] on failure (see core/error/exceptions.dart).
abstract interface class ProductRemoteDataSource {
  Future<ProductPageResponseModel> getProducts({
    required int storeId,
    required int page,
    int limit = 50,
  });
}
