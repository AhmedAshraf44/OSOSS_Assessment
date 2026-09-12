import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';

/// Every session status change the sync engine makes — including ones from
/// background triggers (connectivity restored, app resume), which the
/// screen would otherwise never hear about.
class WatchSessionUpdates {
  const WatchSessionUpdates(this._syncEngine);

  final SyncEngine _syncEngine;

  Stream<CountSession> call() => _syncEngine.sessionUpdates;
}
