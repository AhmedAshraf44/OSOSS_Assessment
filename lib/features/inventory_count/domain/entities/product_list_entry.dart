import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/core/utils/quantity_math.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product.dart';

/// A product joined with the current session's counted quantity for it, if
/// any. This is the row-level view model the product list renders.
class ProductListEntry extends Equatable {
  const ProductListEntry({
    required this.product,
    this.countedQuantity,
    this.hasConflict = false,
  });

  final Product product;

  /// Null means "not counted yet" — distinct from a physical count of 0.
  final int? countedQuantity;

  /// The server rejected this product's version on the last submission, so
  /// the row is flagged until the employee resolves the conflict.
  final bool hasConflict;

  int? get difference => QuantityMath.difference(
    systemQuantity: product.systemQuantity,
    countedQuantity: countedQuantity,
  );

  bool get isCounted => QuantityMath.isCounted(countedQuantity);

  bool get hasDiscrepancy => QuantityMath.hasDiscrepancy(
    systemQuantity: product.systemQuantity,
    countedQuantity: countedQuantity,
  );

  @override
  List<Object?> get props => [product, countedQuantity, hasConflict];
}
