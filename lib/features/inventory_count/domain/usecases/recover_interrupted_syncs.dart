import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';

/// Run once at app startup, before any other sync trigger: resets any
/// session the app was mid-request for when it was last killed back to
/// pendingSync, so it's recoverable instead of stuck in "syncing" forever.
class RecoverInterruptedSyncs {
  const RecoverInterruptedSyncs(this._syncEngine);

  final SyncEngine _syncEngine;

  Future<void> call() => _syncEngine.recoverInterruptedSyncs();
}
