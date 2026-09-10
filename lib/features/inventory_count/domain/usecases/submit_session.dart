import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';

/// Submits a draft session or retries a failed one — [SyncEngine] decides
/// which based on the session's current status — and syncs it right away.
class SubmitSession {
  const SubmitSession(this._syncEngine);

  final SyncEngine _syncEngine;

  Future<CountSession> call(CountSession session) =>
      _syncEngine.submitAndSync(session);
}
