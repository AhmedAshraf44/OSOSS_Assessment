import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/submit_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/submission_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/count_session_state_machine.dart';

/// Maximum automatic retries for a session before it requires an explicit
/// manual retry from the employee.
const int kMaxSyncAttempts = 5;

/// Drives a [CountSession] through submit -> pendingSync -> syncing ->
/// {synced | conflict | failed}, entirely through
/// [CountSessionStateMachine] so an illegal transition fails loudly.
///
/// A session-id mutex ([_inFlight]) prevents two overlapping sync attempts
/// for the same session — the guard against double-tapping submit/retry
/// and against `syncAllPending` racing a manual retry.
class SyncEngine {
  SyncEngine({
    required CountSessionRepository sessionRepository,
    required SubmissionRepository submissionRepository,
  }) : _sessionRepository = sessionRepository,
       _submissionRepository = submissionRepository;

  final CountSessionRepository _sessionRepository;
  final SubmissionRepository _submissionRepository;

  final Set<String> _inFlight = {};

  /// Moves a draft/failed session into the pending-sync queue and
  /// immediately attempts to sync it.
  Future<CountSession> submitAndSync(CountSession session) async {
    final event = session.status == CountSessionStatus.failed
        ? CountSessionEvent.retry
        : CountSessionEvent.submit;
    final pendingStatus = CountSessionStateMachine.next(session.status, event);

    final updateResult = await _sessionRepository.updateStatus(
      session.localId,
      pendingStatus,
    );
    final pendingSession = updateResult.when(
      onSuccess: (value) => value,
      onFailure: (_) => session.copyWith(status: pendingStatus),
    );

    return syncSession(pendingSession);
  }

  /// Attempts to sync one pending session. No-ops (returning [session]
  /// unchanged) if it isn't in [CountSessionStatus.pendingSync] or a sync
  /// for it is already in flight.
  Future<CountSession> syncSession(CountSession session) async {
    if (session.status != CountSessionStatus.pendingSync) return session;
    if (!_inFlight.add(session.localId)) return session;

    try {
      final syncingStatus = CountSessionStateMachine.next(
        session.status,
        CountSessionEvent.syncStart,
      );
      final syncingResult = await _sessionRepository.updateStatus(
        session.localId,
        syncingStatus,
      );
      final syncingSession = syncingResult.when(
        onSuccess: (value) => value,
        onFailure: (_) => session.copyWith(status: syncingStatus),
      );

      final submitResult = await _submissionRepository.submit(syncingSession);

      return await submitResult.when(
        onSuccess: (result) => _applyOutcome(syncingSession, result),
        onFailure: (failure) async {
          final result = await _sessionRepository.markFailed(
            syncingSession.localId,
            failure.message,
          );
          return result.when(
            onSuccess: (value) => value,
            onFailure: (_) => syncingSession.copyWith(
              status: CountSessionStatus.failed,
              lastError: failure.message,
            ),
          );
        },
      );
    } finally {
      _inFlight.remove(session.localId);
    }
  }

  Future<CountSession> _applyOutcome(
    CountSession session,
    SubmitResult result,
  ) async {
    switch (result) {
      case SubmitAccepted(:final serverId):
        final outcome = await _sessionRepository.markSynced(
          session.localId,
          serverId,
        );
        return outcome.when(
          onSuccess: (value) => value,
          onFailure: (_) => session.copyWith(
            status: CountSessionStatus.synced,
            serverId: serverId,
          ),
        );
      case SubmitConflict(:final conflicts):
        final outcome = await _sessionRepository.markConflict(
          session.localId,
          conflicts,
        );
        return outcome.when(
          onSuccess: (value) => value,
          onFailure: (_) => session.copyWith(status: CountSessionStatus.conflict),
        );
    }
  }

  /// Syncs every pending session, e.g. on connectivity restore or app
  /// resume. Sessions [kMaxSyncAttempts] or more failures are left alone —
  /// they need an explicit manual retry.
  Future<void> syncAllPending() async {
    final result = await _sessionRepository.getSessionsPendingSync();
    await result.when(
      onSuccess: (sessions) async {
        for (final session in sessions) {
          if (session.attemptCount >= kMaxSyncAttempts) continue;
          await syncSession(session);
        }
      },
      onFailure: (_) async {},
    );
  }

  /// Crash recovery: run once at app startup, before any sync trigger.
  Future<void> recoverInterruptedSyncs() async {
    await _sessionRepository.recoverInterruptedSyncs();
  }
}
