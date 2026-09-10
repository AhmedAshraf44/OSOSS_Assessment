import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:inventory_count_app/core/utils/widgets/empty_state_view.dart';
import 'package:inventory_count_app/core/utils/widgets/error_state_view.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_page_load_exception.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/product_list_tile.dart';

/// Renders the paginated product list from a [PagingController] owned by
/// the screen — loading, error, empty, and "load more" states are all
/// handled by `infinite_scroll_pagination`'s own builders instead of being
/// hand-rolled.
class ProductPagedListView extends StatelessWidget {
  const ProductPagedListView({super.key, required this.pagingController});

  final PagingController<int, ProductListEntry> pagingController;

  @override
  Widget build(BuildContext context) {
    return PagingListener<int, ProductListEntry>(
      controller: pagingController,
      builder: (context, state, fetchNextPage) =>
          PagedListView<int, ProductListEntry>(
            state: state,
            fetchNextPage: fetchNextPage,
            padding: EdgeInsets.only(bottom: 16.h),
            builderDelegate: PagedChildBuilderDelegate<ProductListEntry>(
              itemBuilder: (context, entry, index) =>
                  ProductListTile(entry: entry),
              firstPageErrorIndicatorBuilder: (context) => ErrorStateView(
                message: _messageFor(state.error),
                onRetry: pagingController.refresh,
              ),
              newPageErrorIndicatorBuilder: (context) => ErrorStateView(
                message: _messageFor(state.error),
                onRetry: fetchNextPage,
              ),
              noItemsFoundIndicatorBuilder: (context) => const EmptyStateView(
                icon: Icons.inventory_2_outlined,
                message:
                    'No products found. Try adjusting your search or filter.',
              ),
            ),
          ),
    );
  }

  String _messageFor(Object? error) {
    if (error is ProductPageLoadException) return error.failure.message;
    return 'Something went wrong. Please try again.';
  }
}
