import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_page.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';

class GetLocalProductPage {
  const GetLocalProductPage(this._repository);

  final ProductRepository _repository;

  Future<ApiResult<ProductListPage>> call({
    required int storeId,
    required String sessionId,
    required int offset,
    required int limit,
    String? searchQuery,
    ProductCountFilter filter = ProductCountFilter.all,
  }) {
    return _repository.getLocalProductPage(
      storeId: storeId,
      sessionId: sessionId,
      offset: offset,
      limit: limit,
      searchQuery: searchQuery,
      filter: filter,
    );
  }
}
