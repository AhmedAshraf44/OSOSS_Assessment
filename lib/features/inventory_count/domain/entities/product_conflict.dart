import 'package:equatable/equatable.dart';

/// One product's version conflict, as detected by the server during
/// submission: the server's version moved on from what the client last
/// saw, so the client's count must not silently overwrite it.
class ProductConflict extends Equatable {
  const ProductConflict({
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

  @override
  List<Object?> get props => [
    productId,
    expectedVersion,
    currentVersion,
    originalSystemQuantity,
    currentSystemQuantity,
    countedQuantity,
  ];
}
