import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/product.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_conflict.dart';

/// A conflict paired with the product info needed to display it clearly —
/// the raw conflict payload only carries a productId.
class ConflictReviewItem extends Equatable {
  const ConflictReviewItem({required this.conflict, this.product});

  final ProductConflict conflict;

  /// Null in the unlikely case the product isn't in the local cache
  /// anymore; the screen falls back to showing the productId.
  final Product? product;

  @override
  List<Object?> get props => [conflict, product];
}
