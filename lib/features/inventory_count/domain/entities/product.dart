import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
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

  /// Server-side optimistic-concurrency version. Snapshotted into
  /// count_items at the moment the employee enters a quantity — see
  /// [ProductListEntry] and CountSessionRepository.
  final int version;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    sku,
    barcode,
    systemQuantity,
    version,
    updatedAt,
  ];
}
