import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';

class ResolveConflicts {
  const ResolveConflicts(this._syncEngine);

  final SyncEngine _syncEngine;

  Future<CountSession> call(
    CountSession session,
    Map<int, ConflictResolution> resolutions,
  ) {
    return _syncEngine.resolveConflictAndResubmit(session, resolutions);
  }
}
