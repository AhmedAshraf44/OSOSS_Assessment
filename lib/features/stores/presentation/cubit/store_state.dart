import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/core/error/failures.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';

sealed class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

final class StoreInitial extends StoreState {
  const StoreInitial();
}

final class StoreLoading extends StoreState {
  const StoreLoading();
}

final class StoreLoaded extends StoreState {
  const StoreLoaded({required this.stores, this.selectedStoreId});

  final List<Store> stores;
  final int? selectedStoreId;

  StoreLoaded copyWith({int? selectedStoreId}) {
    return StoreLoaded(
      stores: stores,
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
    );
  }

  @override
  List<Object?> get props => [stores, selectedStoreId];
}

final class StoreError extends StoreState {
  const StoreError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
