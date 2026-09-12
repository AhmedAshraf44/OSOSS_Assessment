import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_store_sessions.dart';

/// Whether a store has counted work that has not reached the server yet —
/// a draft still being counted, or a submitted session still pending,
/// conflicted, or failed.
///
/// Used before switching stores so the employee is told their count is
/// still waiting instead of silently navigating away from it. Nothing is
/// deleted either way; this only drives the warning.
class HasUnsubmittedCount {
  const HasUnsubmittedCount(this._getStoreSessions);

  final GetStoreSessions _getStoreSessions;

  Future<bool> call(int storeId) async {
    final result = await _getStoreSessions(storeId);

    return result.when(
      onSuccess: (summaries) => summaries.any(
        (summary) =>
            summary.session.status != CountSessionStatus.synced &&
            summary.progress.counted > 0,
      ),
      // A storage failure must not block switching stores — the warning is
      // a courtesy, not a gate.
      onFailure: (_) => false,
    );
  }
}
