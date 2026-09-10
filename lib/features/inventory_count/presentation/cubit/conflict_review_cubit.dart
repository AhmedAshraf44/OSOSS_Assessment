import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/cancel_conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_conflict_review_items.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/resolve_conflicts.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/conflict_review_state.dart';

class ConflictReviewCubit extends Cubit<ConflictReviewState> {
  ConflictReviewCubit({
    required GetConflictReviewItems getConflictReviewItems,
    required ResolveConflicts resolveConflicts,
    required CancelConflictResolution cancelConflictResolution,
  }) : _getConflictReviewItems = getConflictReviewItems,
       _resolveConflicts = resolveConflicts,
       _cancelConflictResolution = cancelConflictResolution,
       super(const ConflictReviewLoading());

  final GetConflictReviewItems _getConflictReviewItems;
  final ResolveConflicts _resolveConflicts;
  final CancelConflictResolution _cancelConflictResolution;

  CountSession? _session;

  Future<void> load(CountSession session) async {
    _session = session;
    emit(const ConflictReviewLoading());

    final result = await _getConflictReviewItems(
      sessionId: session.localId,
      storeId: session.storeId,
    );

    result.when(
      onSuccess: (items) => emit(
        ConflictReviewLoaded(
          items: items,
          resolutions: {
            for (final item in items)
              item.conflict.productId: ConflictResolution.keepMine,
          },
        ),
      ),
      onFailure: (failure) => emit(ConflictReviewError(failure)),
    );
  }

  void setResolution(int productId, ConflictResolution resolution) {
    final current = state;
    if (current is! ConflictReviewLoaded) return;
    emit(
      current.copyWith(
        resolutions: {...current.resolutions, productId: resolution},
      ),
    );
  }

  /// Applies every row's resolution and immediately resubmits. Returns the
  /// updated session so the screen can pop back with the fresh status —
  /// another conflict (or a plain failure) is a real possible outcome
  /// here, not just success.
  Future<CountSession?> confirmAndResubmit() async {
    final current = state;
    final session = _session;
    if (current is! ConflictReviewLoaded || session == null) return null;

    emit(current.copyWith(isSubmitting: true));
    return _resolveConflicts(session, current.resolutions);
  }

  /// Cancels out of review — the session goes back to draft with nothing
  /// lost, ready to be edited and resubmitted later.
  Future<CountSession?> cancel() async {
    final session = _session;
    if (session == null) return null;
    return _cancelConflictResolution(session);
  }
}
