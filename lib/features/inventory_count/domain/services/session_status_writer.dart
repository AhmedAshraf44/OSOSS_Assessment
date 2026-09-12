import 'dart:async';

import 'package:inventory_count_app/core/error/failures.dart';
import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_conflict.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/count_session_state_machine.dart';

/// Persists a session's status change and broadcasts the result.
///
/// Every write falls back to an in-memory copy of the session, so a local
/// storage failure still hands the caller the status it just moved to
/// rather than a stale one.
class SessionStatusWriter {
  SessionStatusWriter(this._repository);

  final CountSessionRepository _repository;
  final StreamController<CountSession> _updates =
      StreamController<CountSession>.broadcast();

  /// Every status change made here, including ones from background
  /// triggers (connectivity restored, app resume), so a screen showing the
  /// session can refresh instead of displaying a stale status.
  Stream<CountSession> get updates => _updates.stream;

  void dispose() => _updates.close();

  /// Moves the session through [event]. [CountSessionStateMachine] runs
  /// first, so an illegal transition throws before anything is persisted.
  Future<CountSession> transition(
    CountSession session,
    CountSessionEvent event, {
    bool publish = true,
  }) {
    final status = CountSessionStateMachine.next(session.status, event);
    return _write(
      () => _repository.updateStatus(session.localId, status),
      () => session.copyWith(status: status),
      publish: publish,
    );
  }

  Future<CountSession> markSynced(CountSession session, int serverId) {
    return _write(
      () => _repository.markSynced(session.localId, serverId),
      () => session.copyWith(
        status: CountSessionStatus.synced,
        serverId: serverId,
      ),
    );
  }

  Future<CountSession> markConflict(
    CountSession session,
    List<ProductConflict> conflicts,
  ) {
    return _write(
      () => _repository.markConflict(session.localId, conflicts),
      () => session.copyWith(status: CountSessionStatus.conflict),
    );
  }

  Future<CountSession> markFailed(CountSession session, Failure failure) {
    final status = CountSessionStateMachine.next(
      session.status,
      CountSessionEvent.syncFail,
    );
    return _write(
      () => _repository.markFailed(session.localId, failure.message),
      () => session.copyWith(status: status, lastError: failure.message),
    );
  }

  Future<CountSession> markPendingRetry(
    CountSession session,
    Failure failure,
  ) {
    final status = CountSessionStateMachine.next(
      session.status,
      CountSessionEvent.defer,
    );
    return _write(
      () => _repository.markPendingRetry(session.localId, failure.message),
      () => session.copyWith(status: status, lastError: failure.message),
    );
  }

  Future<CountSession> _write(
    Future<ApiResult<CountSession>> Function() write,
    CountSession Function() fallback, {
    bool publish = true,
  }) async {
    final result = await write();
    final session = result.when(
      onSuccess: (value) => value,
      onFailure: (_) => fallback(),
    );

    if (publish && !_updates.isClosed) _updates.add(session);
    return session;
  }
}
