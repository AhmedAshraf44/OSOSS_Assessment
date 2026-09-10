import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_model.dart';

/// Matches `GET /stores/{storeId}/products?page=&limit=` ->
/// `{ "data": [...], "page": 1, "totalPages": 10 }`.
class ProductPageResponseModel {
  const ProductPageResponseModel({
    required this.data,
    required this.page,
    required this.totalPages,
  });

  final List<ProductModel> data;
  final int page;
  final int totalPages;

  factory ProductPageResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      final items = json['data'] as List<dynamic>;
      return ProductPageResponseModel(
        data: items
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        totalPages: json['totalPages'] as int,
      );
    } on TypeError {
      throw const MalformedResponseException();
    }
  }
}
