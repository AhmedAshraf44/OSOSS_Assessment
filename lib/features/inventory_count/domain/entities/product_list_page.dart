import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';

class ProductListPage extends Equatable {
  const ProductListPage({required this.entries, required this.hasMore});

  final List<ProductListEntry> entries;
  final bool hasMore;

  @override
  List<Object?> get props => [entries, hasMore];
}
