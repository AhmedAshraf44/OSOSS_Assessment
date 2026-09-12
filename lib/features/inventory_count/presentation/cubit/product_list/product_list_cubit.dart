import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_local_product_page.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_or_create_active_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_session_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/save_counted_quantity.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/submit_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_products_from_server.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/watch_session_updates.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_state_factory.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_page_load_exception.dart';

class ProductListCubit extends Cubit<ProductListState> {
  ProductListCubit({
    required GetOrCreateActiveSession getOrCreateActiveSession,
    required SyncProductsFromServer syncProductsFromServer,
    required GetLocalProductPage getLocalProductPage,
    required SaveCountedQuantity saveCountedQuantity,
    required GetSessionProgress getSessionProgress,
    required SubmitSession submitSession,
    required WatchSessionUpdates watchSessionUpdates,
  }) : _getOrCreateActiveSession = getOrCreateActiveSession,
       _syncProductsFromServer = syncProductsFromServer,
       _getLocalProductPage = getLocalProductPage,
       _saveCountedQuantity = saveCountedQuantity,
       _submitSession = submitSession,
       _stateFactory = ProductListStateFactory(getSessionProgress),
       super(const ProductListInitial()) {
    _sessionSubscription = watchSessionUpdates().listen(_onSessionUpdated);
  }

  final GetOrCreateActiveSession _getOrCreateActiveSession;
  final SyncProductsFromServer _syncProductsFromServer;
  final GetLocalProductPage _getLocalProductPage;
  final SaveCountedQuantity _saveCountedQuantity;
  final SubmitSession _submitSession;
  final ProductListStateFactory _stateFactory;

  late final StreamSubscription<CountSession> _sessionSubscription;

  CountSession? _session;

  CountSession? get currentSession => _session;

  @override
  Future<void> close() {
    _sessionSubscription.cancel();
    return super.close();
  }

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

  Future<void> refreshFromServer() async {
    final current = state;
    if (current is! ProductListReady) return;
    emit(current.copyWith(isSyncing: true));

    final syncResult = await _syncProductsFromServer(current.storeId);
    final progress = await _stateFactory.progressFor(
      current.storeId,
      current.sessionId,
    );

    final latest = state;
    if (latest is! ProductListReady) return;
    final updated = latest.copyWith(isSyncing: false, progress: progress);
    emit(
      syncResult.when(
        onSuccess: (_) => updated,
        onFailure: (failure) => updated.withActionError(failure.message),
      ),
    );
  }

  Future<void> updateCountedQuantity({
    required int productId,
    required int? countedQuantity,
  }) async {
    final current = state;
    if (current is! ProductListReady) return;

    final saveResult = await _saveCountedQuantity(
      sessionId: current.sessionId,
      storeId: current.storeId,
      productId: productId,
      countedQuantity: countedQuantity,
    );

    final progress = await _stateFactory.progressFor(
      current.storeId,
      current.sessionId,
    );
    final latest = state;
    if (latest is! ProductListReady) return;
    final updated = latest.copyWith(progress: progress);
    emit(
      saveResult.when(
        onSuccess: (_) => updated,
        onFailure: (failure) => updated.withActionError(
          'Could not save that count: ${failure.message}',
        ),
      ),
    );
  }

  Future<void> submitSession() async {
    final session = _session;
    if (session == null || state is! ProductListReady) return;

    final updated = await _submitSession(session);
    _session = updated;

    final latest = state;
    if (latest is ProductListReady) emit(latest.withSession(updated));
  }

  Future<void> openSession(CountSession session) async {
    _session = session;
    emit(await _stateFactory.forSession(session));
  }

  Future<bool> reloadActiveSession(int storeId) async {
    final previousId = _session?.localId;

    final sessionResult = await _getOrCreateActiveSession(storeId);
    final session = sessionResult.when(
      onSuccess: (value) => value,
      onFailure: (_) => null,
    );
    if (session == null || session.localId == previousId) return false;

    _session = session;
    emit(await _stateFactory.forSession(session));
    return true;
  }

  Future<void> applyExternallyUpdatedSession(CountSession session) async {
    _session = session;
    final current = state;
    if (current is! ProductListReady) return;

    final progress = await _stateFactory.progressFor(
      current.storeId,
      session.localId,
    );
    emit(current.withSession(session, progress: progress));
  }

  void _onSessionUpdated(CountSession updated) {
    if (updated.localId != _session?.localId) return;
    _session = updated;

    final current = state;
    if (current is ProductListReady) emit(current.withSession(updated));
  }

  Future<CountSession> _ensureSession(int storeId) async {
    final cached = _session;
    if (cached != null) return cached;

    final sessionResult = await _getOrCreateActiveSession(storeId);
    return sessionResult.when(
      onSuccess: (session) async {
        _session = session;
        emit(await _readyStateAfterCatalogSync(session));
        return session;
      },
      onFailure: (failure) => throw ProductPageLoadException(failure),
    );
  }

  Future<ProductListReady> _readyStateAfterCatalogSync(
    CountSession session,
  ) async {
    final syncResult = await _syncProductsFromServer(session.storeId);
    final ready = await _stateFactory.forSession(session);

    return syncResult.when(
      onSuccess: (_) => ready,
      onFailure: (failure) => ready.withActionError(
        'Could not refresh the catalog (${failure.message}). '
        'Showing previously downloaded products.',
      ),
    );
  }
}
