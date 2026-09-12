import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
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
    this.actionError,
  });

  /// A freshly opened session: its own status and progress, nothing
  /// carried over from whatever was on screen before.
  ProductListReady.forSession(CountSession session, this.progress)
    : storeId = session.storeId,
      sessionId = session.localId,
      sessionStatus = session.status,
      attemptCount = session.attemptCount,
      lastError = session.lastError,
      isSyncing = false,
      actionError = null;

  final int storeId;
  final String sessionId;

  /// True while a remote catalog refresh is in flight.
  final bool isSyncing;
  final CountProgress progress;

  /// The count session's own lifecycle status — separate from [isSyncing],
  /// which only reflects the catalog refresh.
  final CountSessionStatus sessionStatus;
  final int attemptCount;

  /// Message from the session's most recent failed *sync* attempt —
  /// persisted, shown by the session-status banner.
  final String? lastError;

  /// Transient error from a one-off action (saving a counted quantity,
  /// refreshing the catalog) that must NOT be confused with [lastError] or
  /// silently dropped — surfaced once as a SnackBar by the screen. Always
  /// reset to null by [copyWith]; set explicitly via [withActionError].
  final String? actionError;

  /// Quantities can only be edited while the session is still a draft.
  /// Once it has been submitted (pending/syncing/synced) or is awaiting
  /// conflict review, the counts are part of a submission and changing
  /// them underneath it would silently diverge from what the server was
  /// told — so a submitted or historical session opens read-only.
  bool get isEditable => sessionStatus == CountSessionStatus.draft;

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

  /// Adopts [session]'s lifecycle fields, keeping everything else on
  /// screen as it is.
  ProductListReady withSession(CountSession session, {CountProgress? progress}) {
    return copyWith(
      sessionStatus: session.status,
      attemptCount: session.attemptCount,
      lastError: session.lastError,
      progress: progress,
    );
  }

  ProductListReady withActionError(String message) {
    return ProductListReady(
      storeId: storeId,
      sessionId: sessionId,
      isSyncing: isSyncing,
      progress: progress,
      sessionStatus: sessionStatus,
      attemptCount: attemptCount,
      lastError: lastError,
      actionError: message,
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
    actionError,
  ];
}
