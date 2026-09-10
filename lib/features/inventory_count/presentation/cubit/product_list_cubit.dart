import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_local_product_page.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_or_create_active_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_session_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/save_counted_quantity.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/submit_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_products_from_server.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_page_load_exception.dart';

/// Owns the session lifecycle, sync status, and count progress. The
/// product *list itself* is owned by a `PagingController` living in the
/// screen's State — this cubit only supplies the page data it asks for
/// (via [fetchProductPage]) and the mutation (via [updateCountedQuantity]);
/// it never holds the loaded entries.
class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit({
    required GetOrCreateActiveSession getOrCreateActiveSession,
    required SyncProductsFromServer syncProductsFromServer,
    required GetLocalProductPage getLocalProductPage,
    required SaveCountedQuantity saveCountedQuantity,
    required GetSessionProgress getSessionProgress,
    required SubmitSession submitSession,
  }) : _getOrCreateActiveSession = getOrCreateActiveSession,
       _syncProductsFromServer = syncProductsFromServer,
       _getLocalProductPage = getLocalProductPage,
       _saveCountedQuantity = saveCountedQuantity,
       _getSessionProgress = getSessionProgress,
       _submitSession = submitSession,
       super(const ProductListInitial());

  final GetOrCreateActiveSession _getOrCreateActiveSession;
  final SyncProductsFromServer _syncProductsFromServer;
  final GetLocalProductPage _getLocalProductPage;
  final SaveCountedQuantity _saveCountedQuantity;
  final GetSessionProgress _getSessionProgress;
  final SubmitSession _submitSession;

  CountSession? _session;

  /// Called from the screen's `PagingController.fetchPage`. Creates the
  /// store's draft session and does a best-effort catalog sync on the very
  /// first call (offline is fine — cached data is used instead); every
  /// call after that just reads the requested page from local storage.
  ///
  /// Throws [ProductPageLoadException] on failure so
  /// infinite_scroll_pagination surfaces it via its own error/retry UI.
  Future<List<ProductListEntry>> fetchProductPage({
    required int storeId,
    required int offset,
    required int limit,
    String? searchQuery,
    ProductCountFilter filter = ProductCountFilter.all,
  }) async {
    final session = await _ensureSession(storeId);

    final pageResult = await _getLocalProductPage(
      storeId: storeId,
      sessionId: session.localId,
      offset: offset,
      limit: limit,
      searchQuery: searchQuery,
      filter: filter,
    );

    return pageResult.when(
      onSuccess: (page) => page.entries,
      onFailure: (failure) => throw ProductPageLoadException(failure),
    );
  }

  Future<CountSession> _ensureSession(int storeId) async {
    final cached = _session;
    if (cached != null) return cached;

    final sessionResult = await _getOrCreateActiveSession(storeId);
    return sessionResult.when(
      onSuccess: (session) async {
        _session = session;
        await _syncProductsFromServer(storeId);
        final progress = await _loadProgress(storeId, session.localId);
        emit(
          ProductListReady(
            storeId: storeId,
            sessionId: session.localId,
            progress: progress,
            sessionStatus: session.status,
            attemptCount: session.attemptCount,
            lastError: session.lastError,
          ),
        );
        return session;
      },
      onFailure: (failure) => throw ProductPageLoadException(failure),
    );
  }

  /// Re-fetches the catalog from the server; the screen follows this with
  /// `PagingController.refresh()` to re-render from the now-updated local
  /// cache.
  Future<void> refreshFromServer() async {
    final current = state;
    if (current is! ProductListReady) return;
    emit(current.copyWith(isSyncing: true));

    await _syncProductsFromServer(current.storeId);
    final progress = await _loadProgress(current.storeId, current.sessionId);

    final latest = state;
    if (latest is ProductListReady) {
      emit(latest.copyWith(isSyncing: false, progress: progress));
    }
  }

  Future<void> updateCountedQuantity({
    required int productId,
    required int? countedQuantity,
  }) async {
    final current = state;
    if (current is! ProductListReady) return;

    await _saveCountedQuantity(
      sessionId: current.sessionId,
      storeId: current.storeId,
      productId: productId,
      countedQuantity: countedQuantity,
    );

    final progress = await _loadProgress(current.storeId, current.sessionId);
    final latest = state;
    if (latest is ProductListReady) emit(latest.copyWith(progress: progress));
  }

  /// Submits the draft session (or retries a failed one — [SubmitSession]
  /// decides which from the session's current status) and syncs it right
  /// away. Safe to call again while a previous call is still running or
  /// after it failed — the engine's single-flight guard and idempotency
  /// key make repeated calls harmless, never a duplicate submission.
  Future<void> submitSession() async {
    final session = _session;
    final current = state;
    if (session == null || current is! ProductListReady) return;

    emit(current.copyWith(sessionStatus: session.status));
    final updated = await _submitSession(session);
    _session = updated;

    final latest = state;
    if (latest is ProductListReady) {
      emit(
        latest.copyWith(
          sessionStatus: updated.status,
          attemptCount: updated.attemptCount,
          lastError: updated.lastError,
        ),
      );
    }
  }

  Future<CountProgress> _loadProgress(int storeId, String sessionId) async {
    final result = await _getSessionProgress(
      storeId: storeId,
      sessionId: sessionId,
    );
    return result.when(
      onSuccess: (progress) => progress,
      onFailure: (_) => CountProgress.zero,
    );
  }
}
