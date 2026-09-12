import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'package:inventory_count_app/core/utils/debouncer.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/navigation/inventory_count_navigator.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/product_list_app_bar.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/product_list_body.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/submit_count_dialog.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.store, this.session});

  final Store store;

  final CountSession? session;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const _pageSize = 50;

  late PagingController<int, ProductListEntry> _pagingController;
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(
    delay: const Duration(milliseconds: 300),
  );

  String _searchQuery = '';
  ProductCountFilter _filter = ProductCountFilter.all;

  @override
  void initState() {
    super.initState();
    _pagingController = _newPagingController();

    final session = widget.session;
    if (session != null) {
      context.read<ProductListCubit>().openSession(session);
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  PagingController<int, ProductListEntry> _newPagingController() {
    return PagingController<int, ProductListEntry>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  void _restartPagination() {
    final old = _pagingController;
    _pagingController = _newPagingController();
    old.dispose();
  }

  Future<List<ProductListEntry>> _fetchPage(int pageKey) {
    return context.read<ProductListCubit>().fetchProductPage(
      storeId: widget.store.id,
      offset: (pageKey - 1) * _pageSize,
      limit: _pageSize,
      searchQuery: _searchQuery,
      filter: _filter,
    );
  }

  void _onSearchChanged(String query) {
    _searchDebouncer.run(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        _restartPagination();
      });
    });
  }

  void _onFilterChanged(ProductCountFilter filter) {
    setState(() {
      _filter = filter;
      _restartPagination();
    });
  }

  Future<void> _onRefreshPressed() async {
    await context.read<ProductListCubit>().refreshFromServer();
    if (mounted) setState(_restartPagination);
  }

  Future<void> _onSubmitPressed(ProductListReady state) async {
    final confirmed = await SubmitCountDialog.show(context, state.progress);
    if (confirmed && mounted) {
      context.read<ProductListCubit>().submitSession();
    }
  }

  Future<void> _onOpenSessions() async {
    final cubit = context.read<ProductListCubit>();
    final changed = await InventoryCountNavigator.openSessions(
      context,
      widget.store,
    );
    if (!changed || !mounted) return;

    final switched = await cubit.reloadActiveSession(widget.store.id);
    if (switched && mounted) setState(_restartPagination);
  }

  Future<void> _onReviewConflict() async {
    final cubit = context.read<ProductListCubit>();
    final session = cubit.currentSession;
    if (session == null) return;

    final updated = await InventoryCountNavigator.openConflictReview(
      context,
      session,
    );
    if (updated == null || !mounted) return;

    await cubit.applyExternallyUpdatedSession(updated);
    if (mounted) setState(_restartPagination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProductListAppBar(
        title: widget.store.name,
        onSubmit: _onSubmitPressed,
        onOpenSessions: widget.session == null ? _onOpenSessions : null,
      ),
      body: ProductListBody(
        pagingController: _pagingController,
        searchController: _searchController,
        filter: _filter,
        onSearchChanged: _onSearchChanged,
        onFilterChanged: _onFilterChanged,
        onRefresh: _onRefreshPressed,
        onReviewConflict: _onReviewConflict,
      ),
    );
  }
}
