import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:inventory_count_app/core/di/injector.dart';
import 'package:inventory_count_app/core/utils/debouncer.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/conflict_review_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/screens/conflict_review_screen.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/product_paged_list_view.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/progress_header.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/search_filter_bar.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/session_status_banner.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.store});

  final Store store;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const _pageSize = 50;

  late final PagingController<int, ProductListEntry> _pagingController;
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));

  String _searchQuery = '';
  ProductCountFilter _filter = ProductCountFilter.all;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, ProductListEntry>(
      getNextPageKey: (state) => state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  Future<List<ProductListEntry>> _fetchPage(int pageKey) {
    return context.read<ProductListCubit>().fetchProductPage(
      storeId: widget.store.id,
      offset: pageKey * _pageSize,
      limit: _pageSize,
      searchQuery: _searchQuery,
      filter: _filter,
    );
  }

  void _onSearchChanged(String query) {
    _searchDebouncer.run(() {
      if (!mounted) return;
      setState(() => _searchQuery = query);
      _pagingController.refresh();
    });
  }

  void _onFilterChanged(ProductCountFilter filter) {
    setState(() => _filter = filter);
    _pagingController.refresh();
  }

  Future<void> _onRefreshPressed() async {
    await context.read<ProductListCubit>().refreshFromServer();
    _pagingController.refresh();
  }

  Future<void> _confirmAndSubmit(ProductListReady state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit count?'),
        content: Text(
          '${state.progress.counted} of ${state.progress.total} products '
          'counted. The session will be queued for synchronization once '
          'you submit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<ProductListCubit>().submitSession();
    }
  }

  Future<void> _onReviewConflict() async {
    final cubit = context.read<ProductListCubit>();
    final session = cubit.currentSession;
    if (session == null) return;

    final updated = await Navigator.of(context).push<CountSession>(
      MaterialPageRoute<CountSession>(
        builder: (_) => BlocProvider(
          create: (_) => sl<ConflictReviewCubit>()..load(session),
          child: ConflictReviewScreen(session: session),
        ),
      ),
    );

    if (updated != null && mounted) {
      await cubit.applyExternallyUpdatedSession(updated);
      _pagingController.refresh();
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
        actions: [
          BlocSelector<ProductListCubit, ProductListState, ProductListReady?>(
            selector: (state) => state is ProductListReady ? state : null,
            builder: (context, readyState) {
              if (readyState == null) return const SizedBox.shrink();
              final canSubmit =
                  readyState.sessionStatus == CountSessionStatus.draft &&
                  readyState.progress.counted > 0;
              return IconButton(
                tooltip: 'Submit count',
                onPressed: canSubmit
                    ? () => _confirmAndSubmit(readyState)
                    : null,
                icon: const Icon(Icons.cloud_upload_outlined),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ProductListCubit, ProductListState>(
        builder: (context, state) {
          return Column(
            children: [
              if (state is ProductListReady) ...[
                SessionStatusBanner(
                  status: state.sessionStatus,
                  attemptCount: state.attemptCount,
                  lastError: state.lastError,
                  onRetry: () => context.read<ProductListCubit>().submitSession(),
                  onReviewConflict: _onReviewConflict,
                ),
                ProgressHeader(
                  progress: state.progress,
                  isSyncing: state.isSyncing,
                  onRefresh: _onRefreshPressed,
                ),
                SearchFilterBar(
                  controller: _searchController,
                  filter: _filter,
                  onSearchChanged: _onSearchChanged,
                  onFilterChanged: _onFilterChanged,
                ),
              ],
              Expanded(
                child: ProductPagedListView(pagingController: _pagingController),
              ),
            ],
          );
        },
      ),
    );
  }
}
