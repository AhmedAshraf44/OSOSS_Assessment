import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';

/// Syncs every session currently pending sync — called on connectivity
/// restore, app resume, or a periodic timer, not only on explicit submit.
class SyncPendingSessions {
  const SyncPendingSessions(this._syncEngine);

  final SyncEngine _syncEngine;

  Future<void> call() => _syncEngine.syncAllPending();
}
