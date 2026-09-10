import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/features/stores/domain/usecases/get_selected_store_id.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/get_stores.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/select_store.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  StoreCubit({
    required GetStores getStores,
    required GetSelectedStoreId getSelectedStoreId,
    required SelectStore selectStore,
  }) : _getStores = getStores,
       _getSelectedStoreId = getSelectedStoreId,
       _selectStore = selectStore,
       super(const StoreInitial());

  final GetStores _getStores;
  final GetSelectedStoreId _getSelectedStoreId;
  final SelectStore _selectStore;

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

  Future<void> selectStore(int storeId) async {
    final current = state;
    if (current is! StoreLoaded) return;

    // TODO: once the inventory_count feature exists, confirm with the
    // employee before switching stores while a draft session for the
    // current store is active, instead of switching silently
    // (Functional Requirement 1: "Handle changing stores while an
    // inventory-count session is active").
    final result = await _selectStore(storeId);
    result.when(
      onSuccess: (_) => emit(current.copyWith(selectedStoreId: storeId)),
      onFailure: (failure) => emit(StoreError(failure)),
    );
  }
}
