import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_conflict.dart';

abstract interface class CountSessionRepository {
  /// The store's current draft session, creating one if none exists — the
  /// single entry point for starting or resuming a count.
  Future<ApiResult<CountSession>> getOrCreateActiveSession(int storeId);

  /// Writes [status] as given; the caller decides it, normally through
  /// `CountSessionStateMachine`.
  Future<ApiResult<CountSession>> updateStatus(
    String sessionId,
    CountSessionStatus status,
  );

  Future<ApiResult<CountSession>> markSynced(String sessionId, int serverId);

  /// Records [errorMessage] and increments the session's attempt count.
  Future<ApiResult<CountSession>> markFailed(
    String sessionId,
    String errorMessage,
  );

  /// Requeues the session because the request never reached the server.
  /// Deliberately does NOT increment the attempt count — nothing was
  /// attempted — so counting offline all day cannot burn the retry budget.
  Future<ApiResult<CountSession>> markPendingRetry(
    String sessionId,
    String reason,
  );

  /// Marks the session conflicted and persists [conflicts] for review.
  Future<ApiResult<CountSession>> markConflict(
    String sessionId,
    List<ProductConflict> conflicts,
  );

  /// Pending sessions across every store — what the sync engine processes.
  Future<ApiResult<List<CountSession>>> getSessionsPendingSync();

  /// Every session recorded for [storeId], newest first.
  Future<ApiResult<List<CountSession>>> getSessionsForStore(int storeId);

  /// Crash recovery: a session still marked syncing at app start means the
  /// app died mid-request. Resets those to pending — safe because retries
  /// are idempotent — instead of leaving them stuck or marking them failed.
  Future<ApiResult<void>> recoverInterruptedSyncs();

  Future<ApiResult<List<ProductConflict>>> getConflicts(String sessionId);

  /// Applies the employee's per-product [resolutions] to the counted items
  /// and clears the stored conflicts. Does NOT change the session's status
  /// — the caller drives that through the state machine.
  Future<ApiResult<void>> applyConflictResolutions(
    String sessionId,
    Map<int, ConflictResolution> resolutions,
  );
}
