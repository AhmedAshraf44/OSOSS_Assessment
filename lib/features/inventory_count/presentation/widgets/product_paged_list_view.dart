import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/core/utils/widgets/empty_state_view.dart';
import 'package:inventory_count_app/core/utils/widgets/error_state_view.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_page_load_exception.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/product_list_tile.dart';

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
              firstPageProgressIndicatorBuilder: (context) =>
                  const Center(child: CircularProgressIndicator()),
              newPageProgressIndicatorBuilder: (context) => Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Loading more products…',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              noMoreItemsIndicatorBuilder: (context) => Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: Text(
                    'End of list',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
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
