import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_or_create_active_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_store_sessions.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/sessions/sessions_state.dart';

class SessionsCubit extends Cubit<SessionsState> {
  SessionsCubit({
    required GetStoreSessions getStoreSessions,
    required GetOrCreateActiveSession getOrCreateActiveSession,
  }) : _getStoreSessions = getStoreSessions,
       _getOrCreateActiveSession = getOrCreateActiveSession,
       super(const SessionsLoading());

  final GetStoreSessions _getStoreSessions;
  final GetOrCreateActiveSession _getOrCreateActiveSession;

  Future<void> load(int storeId) async {
    emit(const SessionsLoading());
    final result = await _getStoreSessions(storeId);
    result.when(
      onSuccess: (summaries) => emit(SessionsLoaded(summaries)),
      onFailure: (failure) => emit(SessionsError(failure)),
    );
  }

  /// Starts a count for this store. Because only one active session per
  /// store is allowed, this returns the existing draft if there already is
  /// one (i.e. it resumes) instead of creating a second.
  Future<void> startOrResume(int storeId) async {
    await _getOrCreateActiveSession(storeId);
    await load(storeId);
  }
}
