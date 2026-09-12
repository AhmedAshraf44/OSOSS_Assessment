import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/progress_header.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/search_filter_bar.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/session_status_banner.dart';

/// Everything above the product list: sync status, count progress, and the
/// search/filter controls.
class ProductListHeader extends StatelessWidget {
  const ProductListHeader({
    super.key,
    required this.state,
    required this.searchController,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onReviewConflict,
  });

  final ProductListReady state;
  final TextEditingController searchController;
  final ProductCountFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ProductCountFilter> onFilterChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onReviewConflict;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SessionStatusBanner(
          status: state.sessionStatus,
          attemptCount: state.attemptCount,
          lastError: state.lastError,
          onRetry: () => context.read<ProductListCubit>().submitSession(),
          onReviewConflict: onReviewConflict,
        ),
        ProgressHeader(
          progress: state.progress,
          isSyncing: state.isSyncing,
          onRefresh: onRefresh,
        ),
        SearchFilterBar(
          controller: searchController,
          filter: filter,
          onSearchChanged: onSearchChanged,
          onFilterChanged: onFilterChanged,
        ),
      ],
    );
  }
}
