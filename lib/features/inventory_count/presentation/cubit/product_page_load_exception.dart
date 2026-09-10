import 'package:inventory_count_app/core/error/failures.dart';

/// Thrown by [ProductListCubit.fetchProductPage] so
/// `infinite_scroll_pagination` captures the [Failure] in `PagingState.error`
/// for its built-in error/retry UI.
class ProductPageLoadException implements Exception {
  const ProductPageLoadException(this.failure);

  final Failure failure;
}
