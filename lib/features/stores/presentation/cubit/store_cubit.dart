import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/features/inventory_count/domain/usecases/has_unsubmitted_count.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/get_selected_store_id.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/get_stores.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/select_store.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  StoreCubit({
    required GetStores getStores,
    required GetSelectedStoreId getSelectedStoreId,
    required SelectStore selectStore,
    required HasUnsubmittedCount hasUnsubmittedCount,
  }) : _getStores = getStores,
       _getSelectedStoreId = getSelectedStoreId,
       _selectStore = selectStore,
       _hasUnsubmittedCount = hasUnsubmittedCount,
       super(const StoreInitial());

  final GetStores _getStores;
  final GetSelectedStoreId _getSelectedStoreId;
  final SelectStore _selectStore;
  final HasUnsubmittedCount _hasUnsubmittedCount;

  Future<void> loadStores() async {
    emit(const StoreLoading());

    final storesResult = await _getStores();
    final selectedResult = await _getSelectedStoreId();

    storesResult.when(
      onSuccess: (stores) {
        final selectedStoreId = selectedResult.when(
          onSuccess: (id) => id,
          onFailure: (_) => null,
        );
        emit(StoreLoaded(stores: stores, selectedStoreId: selectedStoreId));
      },
      onFailure: (failure) => emit(StoreError(failure)),
    );
  }

  /// Whether picking [storeId] would walk away from a count on the
  /// currently selected store that has not reached the server yet.
  ///
  /// The caller confirms with the employee before calling [selectStore].
  /// Switching never discards anything — each store's session and counted
  /// quantities stay on the device, scoped to that store — but leaving
  /// silently would hide unsynced work.
  Future<bool> isLeavingUnsubmittedCount(int storeId) async {
    final current = state;
    if (current is! StoreLoaded) return false;

    final selectedStoreId = current.selectedStoreId;
    if (selectedStoreId == null || selectedStoreId == storeId) return false;

    return _hasUnsubmittedCount(selectedStoreId);
  }

  Future<void> selectStore(int storeId) async {
    final current = state;
    if (current is! StoreLoaded) return;

    final result = await _selectStore(storeId);
    result.when(
      onSuccess: (_) => emit(current.copyWith(selectedStoreId: storeId)),
      onFailure: (failure) => emit(StoreError(failure)),
    );
  }
}
