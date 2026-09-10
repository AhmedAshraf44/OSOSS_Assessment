import 'package:equatable/equatable.dart';

/// One counted product as it will be sent in a submission payload.
class CountedItem extends Equatable {
  const CountedItem({
    required this.productId,
    required this.countedQuantity,
    required this.expectedVersion,
  });

  final int productId;
  final int countedQuantity;
  final int expectedVersion;

  @override
  List<Object?> get props => [productId, countedQuantity, expectedVersion];
}
