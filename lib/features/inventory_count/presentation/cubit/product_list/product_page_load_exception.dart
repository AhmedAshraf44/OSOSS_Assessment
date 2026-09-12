import 'package:inventory_count_app/core/error/failures.dart';

class ProductPageLoadException implements Exception {
  const ProductPageLoadException(this.failure);

  final Failure failure;
}
