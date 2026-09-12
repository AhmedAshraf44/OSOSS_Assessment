import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_conflict.dart';

class ProductConflictModel {
  const ProductConflictModel({
    required this.productId,
    required this.expectedVersion,
    required this.currentVersion,
    required this.originalSystemQuantity,
    required this.currentSystemQuantity,
    required this.countedQuantity,
  });

  final int productId;
  final int expectedVersion;
  final int currentVersion;
  final int originalSystemQuantity;
  final int currentSystemQuantity;
  final int countedQuantity;

  /// Matches the assessment's conflict response shape:
  /// `{productId, expectedVersion, currentVersion, originalSystemQuantity,
  /// currentSystemQuantity, countedQuantity}`.
  factory ProductConflictModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProductConflictModel(
        productId: json['productId'] as int,
        expectedVersion: json['expectedVersion'] as int,
        currentVersion: json['currentVersion'] as int,
        originalSystemQuantity: json['originalSystemQuantity'] as int,
        currentSystemQuantity: json['currentSystemQuantity'] as int,
        countedQuantity: json['countedQuantity'] as int,
      );
    } on TypeError {
      throw const MalformedResponseException();
    }
  }

  factory ProductConflictModel.fromEntity(ProductConflict conflict) {
    return ProductConflictModel(
      productId: conflict.productId,
      expectedVersion: conflict.expectedVersion,
      currentVersion: conflict.currentVersion,
      originalSystemQuantity: conflict.originalSystemQuantity,
      currentSystemQuantity: conflict.currentSystemQuantity,
      countedQuantity: conflict.countedQuantity,
    );
  }

  factory ProductConflictModel.fromDbRow(Map<String, Object?> row) {
    try {
      return ProductConflictModel(
        productId: row['product_id']! as int,
        expectedVersion: row['expected_version']! as int,
        currentVersion: row['current_version']! as int,
        originalSystemQuantity: row['original_system_quantity']! as int,
        currentSystemQuantity: row['current_system_quantity']! as int,
        countedQuantity: row['counted_quantity']! as int,
      );
    } on TypeError {
      throw const LocalStorageException('Corrupt sync_conflicts row.');
    }
  }

  Map<String, Object?> toDbMap(String sessionId) => {
    'session_id': sessionId,
    'product_id': productId,
    'expected_version': expectedVersion,
    'current_version': currentVersion,
    'original_system_quantity': originalSystemQuantity,
    'current_system_quantity': currentSystemQuantity,
    'counted_quantity': countedQuantity,
    'resolution': null,
  };

  ProductConflict toEntity() => ProductConflict(
    productId: productId,
    expectedVersion: expectedVersion,
    currentVersion: currentVersion,
    originalSystemQuantity: originalSystemQuantity,
    currentSystemQuantity: currentSystemQuantity,
    countedQuantity: countedQuantity,
  );
}
