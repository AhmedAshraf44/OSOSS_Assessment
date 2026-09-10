import 'package:inventory_count_app/features/inventory_count/data/models/count_session_model.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_conflict_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';

/// Throws [LocalStorageException] on failure.
abstract interface class CountSessionLocalDataSource {
  Future<CountSessionModel?> getActiveDraftSession(int storeId);
  Future<void> insertSession(CountSessionModel session);

  Future<CountSessionModel> updateStatus(
    String sessionId,
    CountSessionStatus status,
  );

  Future<CountSessionModel> markSynced(String sessionId, int serverId);

  Future<CountSessionModel> markFailed(String sessionId, String errorMessage);

  /// Sets the session to [CountSessionStatus.conflict] and replaces any
  /// previously stored conflicts for it with [conflicts].
  Future<CountSessionModel> markConflict(
    String sessionId,
    List<ProductConflictModel> conflicts,
  );

  Future<List<CountSessionModel>> getSessionsPendingSync();

  /// Resets every session still marked [CountSessionStatus.syncing] back to
  /// [CountSessionStatus.pendingSync] — crash recovery, run once at startup.
  Future<void> recoverInterruptedSyncs();

  Future<List<ProductConflictModel>> getConflicts(String sessionId);

  Future<void> clearConflicts(String sessionId);
}
