import 'package:inventory_count_app/features/inventory_count/data/datasources/count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_resolution.dart';

/// Writes the employee's conflict decisions back onto the session's
/// counted items.
///
/// Each resolved item also snapshots the server's current version as its
/// new expected version — that is what lets the resubmission pass version
/// checks instead of conflicting again on the same change.
class ConflictResolutionApplier {
  const ConflictResolutionApplier({
    required CountSessionLocalDataSource sessionLocalDataSource,
    required ProductLocalDataSource productLocalDataSource,
  }) : _sessionLocalDataSource = sessionLocalDataSource,
       _productLocalDataSource = productLocalDataSource;

  final CountSessionLocalDataSource _sessionLocalDataSource;
  final ProductLocalDataSource _productLocalDataSource;

  Future<void> apply(
    String sessionId,
    Map<int, ConflictResolution> resolutions,
  ) async {
    final conflicts = await _sessionLocalDataSource.getConflicts(sessionId);

    for (final conflict in conflicts) {
      final resolution =
          resolutions[conflict.productId] ?? ConflictResolution.keepMine;

      await _productLocalDataSource.upsertCountedQuantity(
        sessionId: sessionId,
        productId: conflict.productId,
        expectedVersion: conflict.currentVersion,
        countedQuantity: resolution == ConflictResolution.keepMine
            ? conflict.countedQuantity
            : conflict.currentSystemQuantity,
      );
    }

    await _sessionLocalDataSource.clearConflicts(sessionId);
  }
}
