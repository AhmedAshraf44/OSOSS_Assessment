import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';

class CancelConflictResolution {
  const CancelConflictResolution(this._syncEngine);

  final SyncEngine _syncEngine;

  Future<CountSession> call(CountSession session) =>
      _syncEngine.cancelConflict(session);
}
