import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/count_session_state_machine.dart';

void main() {
  group('CountSessionStateMachine.next', () {
    test('draft -> pendingSync on submit', () {
      expect(
        CountSessionStateMachine.next(
          CountSessionStatus.draft,
          CountSessionEvent.submit,
        ),
        CountSessionStatus.pendingSync,
      );
    });

    test('pendingSync -> syncing on syncStart', () {
      expect(
        CountSessionStateMachine.next(
          CountSessionStatus.pendingSync,
          CountSessionEvent.syncStart,
        ),
        CountSessionStatus.syncing,
      );
    });

    test('syncing -> synced on syncSucceed', () {
      expect(
        CountSessionStateMachine.next(
          CountSessionStatus.syncing,
          CountSessionEvent.syncSucceed,
        ),
        CountSessionStatus.synced,
      );
    });

    test('syncing -> conflict on syncConflict', () {
      expect(
        CountSessionStateMachine.next(
          CountSessionStatus.syncing,
          CountSessionEvent.syncConflict,
        ),
        CountSessionStatus.conflict,
      );
    });

    test('syncing -> failed on syncFail', () {
      expect(
        CountSessionStateMachine.next(
          CountSessionStatus.syncing,
          CountSessionEvent.syncFail,
        ),
        CountSessionStatus.failed,
      );
    });

    test('failed -> pendingSync on retry', () {
      expect(
        CountSessionStateMachine.next(
          CountSessionStatus.failed,
          CountSessionEvent.retry,
        ),
        CountSessionStatus.pendingSync,
      );
    });

    test('syncing -> pendingSync on defer (request never left the device)', () {
      expect(
        CountSessionStateMachine.next(
          CountSessionStatus.syncing,
          CountSessionEvent.defer,
        ),
        CountSessionStatus.pendingSync,
      );
    });

    test('conflict -> pendingSync on resolve', () {
      expect(
        CountSessionStateMachine.next(
          CountSessionStatus.conflict,
          CountSessionEvent.resolve,
        ),
        CountSessionStatus.pendingSync,
      );
    });

    test('conflict -> draft on cancel', () {
      expect(
        CountSessionStateMachine.next(
          CountSessionStatus.conflict,
          CountSessionEvent.cancel,
        ),
        CountSessionStatus.draft,
      );
    });

    test('throws when a synced session is asked to sync again', () {
      expect(
        () => CountSessionStateMachine.next(
          CountSessionStatus.synced,
          CountSessionEvent.syncStart,
        ),
        throwsStateError,
      );
    });

    test('throws when a draft session is asked to sync directly', () {
      expect(
        () => CountSessionStateMachine.next(
          CountSessionStatus.draft,
          CountSessionEvent.syncStart,
        ),
        throwsStateError,
      );
    });

    test('throws when a conflicted session is retried directly', () {
      // Conflicts are resolved through the review flow, not a plain retry.
      expect(
        () => CountSessionStateMachine.next(
          CountSessionStatus.conflict,
          CountSessionEvent.retry,
        ),
        throwsStateError,
      );
    });
  });

  group('CountSessionStateMachine.canApply', () {
    test('reports legal transitions without throwing', () {
      expect(
        CountSessionStateMachine.canApply(
          CountSessionStatus.failed,
          CountSessionEvent.retry,
        ),
        isTrue,
      );
    });

    test('reports illegal transitions without throwing', () {
      expect(
        CountSessionStateMachine.canApply(
          CountSessionStatus.synced,
          CountSessionEvent.retry,
        ),
        isFalse,
      );
    });
  });
}
