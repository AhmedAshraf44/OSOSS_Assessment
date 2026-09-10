import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';

sealed class ProductListState extends Equatable {
  const ProductListState();

  @override
  List<Object?> get props => [];
}

/// Session not created/loaded yet. The product list itself is still shown
/// during this state — its own first-page loading/error indicator (driven
/// by PagingController) covers the wait; this state only gates the header
/// and search bar, which need [ProductListReady.sessionId] to exist.
final class ProductListInitial extends ProductListState {
  const ProductListInitial();
}

final class ProductListReady extends ProductListState {
  const ProductListReady({
    required this.storeId,
    required this.sessionId,
    this.isSyncing = false,
    this.progress = CountProgress.zero,
    this.sessionStatus = CountSessionStatus.draft,
    this.attemptCount = 0,
    this.lastError,
  });

  final int storeId;
  final String sessionId;

  /// True while a remote catalog refresh is in flight.
  final bool isSyncing;
  final CountProgress progress;

  /// The count session's own lifecycle status — separate from [isSyncing],
  /// which only reflects the catalog refresh.
  final CountSessionStatus sessionStatus;
  final int attemptCount;
  final String? lastError;

  ProductListReady copyWith({
    bool? isSyncing,
    CountProgress? progress,
    CountSessionStatus? sessionStatus,
    int? attemptCount,
    String? lastError,
  }) {
    return ProductListReady(
      storeId: storeId,
      sessionId: sessionId,
      isSyncing: isSyncing ?? this.isSyncing,
      progress: progress ?? this.progress,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [
    storeId,
    sessionId,
    isSyncing,
    progress,
    sessionStatus,
    attemptCount,
    lastError,
  ];
}
