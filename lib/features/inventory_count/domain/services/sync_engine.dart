import 'package:inventory_count_app/core/error/failures.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/submit_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/submission_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/count_session_state_machine.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/session_status_writer.dart';

/// Maximum automatic retries for a session before it requires an explicit
/// manual retry from the employee.
const int kMaxSyncAttempts = 5;

/// Drives a [CountSession] through submit -> pendingSync -> syncing ->
/// {synced | conflict | failed}. Status writes go through
/// [SessionStatusWriter]; a session-id mutex ([_inFlight]) keeps two
/// attempts for the same session from overlapping.
class SyncEngine {
  SyncEngine({
    required CountSessionRepository sessionRepository,
    required SubmissionRepository submissionRepository,
  }) : _sessionRepository = sessionRepository,
       _submissionRepository = submissionRepository,
       _statusWriter = SessionStatusWriter(sessionRepository);

  final CountSessionRepository _sessionRepository;
  final SubmissionRepository _submissionRepository;
  final SessionStatusWriter _statusWriter;

  final Set<String> _inFlight = {};

  Stream<CountSession> get sessionUpdates => _statusWriter.updates;

  void dispose() => _statusWriter.dispose();

  /// Moves a draft/failed session into the pending-sync queue and
  /// immediately attempts to sync it.
  Future<CountSession> submitAndSync(CountSession session) async {
    final event = session.status == CountSessionStatus.failed
        ? CountSessionEvent.retry
        : CountSessionEvent.submit;

    return syncSession(await _statusWriter.transition(session, event));
  }

  /// Attempts to sync one pending session. No-ops (returning [session]
  /// unchanged) if it isn't in [CountSessionStatus.pendingSync] or a sync
  /// for it is already in flight.
  Future<CountSession> syncSession(CountSession session) async {
    if (session.status != CountSessionStatus.pendingSync) return session;
    if (!_inFlight.add(session.localId)) return session;

    try {
      final syncing = await _statusWriter.transition(
        session,
        CountSessionEvent.syncStart,
      );
      final submitResult = await _submissionRepository.submit(syncing);

      return await submitResult.when(
        onSuccess: (result) => _applyOutcome(syncing, result),
        onFailure: (failure) => _applyFailure(syncing, failure),
      );
    } finally {
      _inFlight.remove(session.localId);
    }
  }

  Future<CountSession> _applyOutcome(
    CountSession session,
    SubmitResult result,
  ) {
    return switch (result) {
      SubmitAccepted(:final serverId) => _statusWriter.markSynced(
        session,
        serverId,
      ),
      SubmitConflict(:final conflicts) => _statusWriter.markConflict(
        session,
        conflicts,
      ),
    };
  }

  /// A [NetworkFailure] means the request never left the device, so the
  /// session stays queued and is picked up once connectivity returns — the
  /// employee has nothing to fix, and "Failed" would be a lie. Anything
  /// else did reach the wire and genuinely failed, so it becomes
  /// [CountSessionStatus.failed] with an explicit retry action.
  Future<CountSession> _applyFailure(CountSession session, Failure failure) {
    return failure is NetworkFailure
        ? _statusWriter.markPendingRetry(session, failure)
        : _statusWriter.markFailed(session, failure);
  }

  /// Syncs every pending session, e.g. on connectivity restore or app
  /// resume. Sessions with [kMaxSyncAttempts] or more failures are left
  /// alone — they need an explicit manual retry.
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
  Future<void> recoverInterruptedSyncs() =>
      _sessionRepository.recoverInterruptedSyncs();

  /// Applies the employee's conflict [resolutions] and resubmits. A fresh
  /// conflict is possible here too (another sale could land during review)
  /// — handled the same way as the first one, not a special case.
  Future<CountSession> resolveConflictAndResubmit(
    CountSession session,
    Map<int, ConflictResolution> resolutions,
  ) async {
    await _sessionRepository.applyConflictResolutions(
      session.localId,
      resolutions,
    );

    return syncSession(
      await _statusWriter.transition(session, CountSessionEvent.resolve),
    );
  }

  /// Leaves conflict review without resolving anything — the session goes
  /// back to draft so the employee can adjust counts and resubmit later.
  /// Nothing already counted is lost.
  Future<CountSession> cancelConflict(CountSession session) {
    return _statusWriter.transition(
      session,
      CountSessionEvent.cancel,
      publish: false,
    );
  }
}
