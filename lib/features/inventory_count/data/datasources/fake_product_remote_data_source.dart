import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_page_response_model.dart';

class FakeProductRemoteDataSource implements ProductRemoteDataSource {
  const FakeProductRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<ProductPageResponseModel> getProducts({
    required int storeId,
    required int page,
    int limit = 50,
  }) async {
    final json = await _backend.fetchProducts(
      storeId: storeId,
      page: page,
      limit: limit,
    );
    return ProductPageResponseModel.fromJson(json);
  }
}
