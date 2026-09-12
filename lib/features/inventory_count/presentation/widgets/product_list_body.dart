import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/product_list_header.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/product_paged_list_view.dart';

class ProductListBody extends StatelessWidget {
  const ProductListBody({
    super.key,
    required this.pagingController,
    required this.searchController,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onReviewConflict,
  });

  final PagingController<int, ProductListEntry> pagingController;
  final TextEditingController searchController;
  final ProductCountFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ProductCountFilter> onFilterChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onReviewConflict;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductListCubit, ProductListState>(
      listenWhen: (previous, current) =>
          current is ProductListReady && current.actionError != null,
      listener: _showActionError,
      builder: (context, state) {
        return Column(
          children: [
            if (state is ProductListReady)
              ProductListHeader(
                state: state,
                searchController: searchController,
                filter: filter,
                onSearchChanged: onSearchChanged,
                onFilterChanged: onFilterChanged,
                onRefresh: onRefresh,
                onReviewConflict: onReviewConflict,
              ),
            Expanded(
              child: ProductPagedListView(pagingController: pagingController),
            ),
          ],
        );
      },
    );
  }

  void _showActionError(BuildContext context, ProductListState state) {
    if (state is! ProductListReady || state.actionError == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(state.actionError!)));
  }
}
