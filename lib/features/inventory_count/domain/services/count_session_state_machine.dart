import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';

/// Events that can move a [CountSession] through its lifecycle.
enum CountSessionEvent {
  /// Employee taps "Submit" on a draft session.
  submit,

  /// The sync engine has picked up a pending session and started the
  /// network request.
  syncStart,

  /// The server accepted the submission.
  syncSucceed,

  /// The server reported a version conflict.
  syncConflict,

  /// The request failed (timeout, server error, malformed response, ...) —
  /// it actually went out and came back wrong.
  syncFail,

  /// The request never left the device (no connectivity), so the session
  /// goes back to the pending queue rather than being marked failed: there
  /// is nothing for the employee to "retry", it just waits for a
  /// connection.
  defer,

  /// Employee (or the engine, for a transient failure) retries a failed
  /// session.
  retry,

  /// Employee resolved every conflicted product and confirmed
  /// resubmission.
  resolve,

  /// Employee canceled out of the conflict review instead of resolving it.
  cancel,
}

/// Pure, side-effect-free rules for [CountSessionStatus] transitions —
/// no Flutter, no IO, fully unit-testable in isolation. Every status
/// change the app makes goes through this so an illegal transition (e.g.
/// a [synced] session going back to [syncing]) fails loudly instead of
/// silently corrupting state.
class CountSessionStateMachine {
  const CountSessionStateMachine._();

  static const Map<CountSessionStatus, Set<CountSessionEvent>> _allowedEvents = {
    CountSessionStatus.draft: {CountSessionEvent.submit},
    CountSessionStatus.readyToSubmit: {CountSessionEvent.submit},
    CountSessionStatus.pendingSync: {CountSessionEvent.syncStart},
    CountSessionStatus.syncing: {
      CountSessionEvent.syncSucceed,
      CountSessionEvent.syncConflict,
      CountSessionEvent.syncFail,
      CountSessionEvent.defer,
    },
    CountSessionStatus.conflict: {
      CountSessionEvent.resolve,
      CountSessionEvent.cancel,
    },
    CountSessionStatus.synced: {},
    CountSessionStatus.failed: {CountSessionEvent.retry},
  };

  /// Returns the next status for [current] after [event], or throws a
  /// [StateError] if that transition isn't allowed.
  static CountSessionStatus next(
    CountSessionStatus current,
    CountSessionEvent event,
  ) {
    final allowed = _allowedEvents[current] ?? const <CountSessionEvent>{};
    if (!allowed.contains(event)) {
      throw StateError(
        'Cannot apply $event to a session in $current state.',
      );
    }
    return switch (event) {
      CountSessionEvent.submit => CountSessionStatus.pendingSync,
      CountSessionEvent.syncStart => CountSessionStatus.syncing,
      CountSessionEvent.syncSucceed => CountSessionStatus.synced,
      CountSessionEvent.syncConflict => CountSessionStatus.conflict,
      CountSessionEvent.syncFail => CountSessionStatus.failed,
      CountSessionEvent.defer => CountSessionStatus.pendingSync,
      CountSessionEvent.retry => CountSessionStatus.pendingSync,
      CountSessionEvent.resolve => CountSessionStatus.pendingSync,
      CountSessionEvent.cancel => CountSessionStatus.draft,
    };
  }

  /// Whether [event] is legal for a session currently in [current].
  static bool canApply(CountSessionStatus current, CountSessionEvent event) {
    return (_allowedEvents[current] ?? const <CountSessionEvent>{})
        .contains(event);
  }
}
