import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.systemQuantity,
    required this.version,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String sku;
  final String barcode;
  final int systemQuantity;
  final int version;
  final DateTime updatedAt;

  /// Matches the assessment's product JSON shape:
  /// `{id, name, sku, barcode, systemQuantity, version, updatedAt}`.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProductModel(
        id: json['id'] as int,
        name: json['name'] as String,
        sku: json['sku'] as String,
        barcode: json['barcode'] as String,
        systemQuantity: json['systemQuantity'] as int,
        version: json['version'] as int,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
    } on TypeError {
      throw const MalformedResponseException();
    } on FormatException {
      throw const MalformedResponseException();
    }
  }

  factory ProductModel.fromDbRow(Map<String, Object?> row) {
    try {
      return ProductModel(
        id: row['id']! as int,
        name: row['name']! as String,
        sku: row['sku']! as String,
        barcode: row['barcode']! as String,
        systemQuantity: row['system_quantity']! as int,
        version: row['version']! as int,
        updatedAt: DateTime.parse(row['updated_at']! as String),
      );
    } on TypeError {
      throw const LocalStorageException('Corrupt product row.');
    }
  }

  /// Builds the row-level view model from a query result that joins
  /// `products` with `count_items` (aliased `counted_quantity`) and
  /// `sync_conflicts` (aliased `has_conflict`).
  static ProductListEntry entryFromRow(Map<String, Object?> row) {
    return ProductListEntry(
      product: ProductModel.fromDbRow(row).toEntity(),
      countedQuantity: row['counted_quantity'] as int?,
      hasConflict: (row['has_conflict'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toDbMap(int storeId) => {
    'id': id,
    'store_id': storeId,
    'name': name,
    'sku': sku,
    'barcode': barcode,
    'system_quantity': systemQuantity,
    'version': version,
    'updated_at': updatedAt.toIso8601String(),
  };

  Product toEntity() => Product(
    id: id,
    name: name,
    sku: sku,
    barcode: barcode,
    systemQuantity: systemQuantity,
    version: version,
    updatedAt: updatedAt,
  );
}
