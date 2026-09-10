import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_conflict.dart';

abstract interface class CountSessionRepository {
  /// Returns the store's current draft session, creating one if none
  /// exists. Only one active session per store is required for this
  /// assessment, so this is the single entry point for starting/resuming a
  /// count.
  Future<ApiResult<CountSession>> getOrCreateActiveSession(int storeId);

  /// Persists [status] for the session and returns the updated session.
  /// Callers decide the next status (typically via
  /// [CountSessionStateMachine]) — this just writes it.
  Future<ApiResult<CountSession>> updateStatus(
    String sessionId,
    CountSessionStatus status,
  );

  /// Marks the session synced with the server-assigned id.
  Future<ApiResult<CountSession>> markSynced(String sessionId, int serverId);

  /// Marks the session failed, recording [errorMessage] and incrementing
  /// its attempt count.
  Future<ApiResult<CountSession>> markFailed(
    String sessionId,
    String errorMessage,
  );

  /// Marks the session conflicted and persists the raw conflicts so a
  /// later review screen can read them back.
  Future<ApiResult<CountSession>> markConflict(
    String sessionId,
    List<ProductConflict> conflicts,
  );

  /// Sessions currently in [CountSessionStatus.pendingSync] across every
  /// store — what the sync engine processes on each run.
  Future<ApiResult<List<CountSession>>> getSessionsPendingSync();

  /// Crash recovery: any session still marked [CountSessionStatus.syncing]
  /// at app start means the app died mid-request. Resets those back to
  /// [CountSessionStatus.pendingSync] — safe because retries are
  /// idempotent — instead of leaving them stuck or marking them failed.
  Future<ApiResult<void>> recoverInterruptedSyncs();
}
