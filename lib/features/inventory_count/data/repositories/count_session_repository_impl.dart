import 'package:inventory_count_app/core/auth/mock_session.dart';
import 'package:inventory_count_app/core/error/exception_mapper.dart';
import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/core/utils/id_generator.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/count_session_model.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_conflict_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_conflict.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';

class CountSessionRepositoryImpl implements CountSessionRepository {
  const CountSessionRepositoryImpl({
    required CountSessionLocalDataSource localDataSource,
    required ProductLocalDataSource productLocalDataSource,
    required IdGenerator idGenerator,
  }) : _localDataSource = localDataSource,
       _productLocalDataSource = productLocalDataSource,
       _idGenerator = idGenerator;

  final CountSessionLocalDataSource _localDataSource;
  final ProductLocalDataSource _productLocalDataSource;
  final IdGenerator _idGenerator;

  @override
  Future<ApiResult<CountSession>> getOrCreateActiveSession(int storeId) {
    return guardApiCall(() async {
      final existing = await _localDataSource.getActiveDraftSession(storeId);
      if (existing != null) return existing.toEntity();

      final now = DateTime.now();
      final session = CountSessionModel(
        localId: _idGenerator.generate(),
        storeId: storeId,
        employeeId: MockSession.employeeId,
        status: CountSessionStatus.draft,
        createdAt: now,
        updatedAt: now,
        idempotencyKey: _idGenerator.generate(),
      );
      await _localDataSource.insertSession(session);
      return session.toEntity();
    });
  }

  @override
  Future<ApiResult<CountSession>> updateStatus(
    String sessionId,
    CountSessionStatus status,
  ) {
    return guardApiCall(() async {
      final updated = await _localDataSource.updateStatus(sessionId, status);
      return updated.toEntity();
    });
  }

  @override
  Future<ApiResult<CountSession>> markSynced(String sessionId, int serverId) {
    return guardApiCall(() async {
      final updated = await _localDataSource.markSynced(sessionId, serverId);
      return updated.toEntity();
    });
  }

  @override
  Future<ApiResult<CountSession>> markFailed(
    String sessionId,
    String errorMessage,
  ) {
    return guardApiCall(() async {
      final updated = await _localDataSource.markFailed(sessionId, errorMessage);
      return updated.toEntity();
    });
  }

  @override
  Future<ApiResult<CountSession>> markConflict(
    String sessionId,
    List<ProductConflict> conflicts,
  ) {
    return guardApiCall(() async {
      final models = conflicts
          .map(
            (c) => ProductConflictModel(
              productId: c.productId,
              expectedVersion: c.expectedVersion,
              currentVersion: c.currentVersion,
              originalSystemQuantity: c.originalSystemQuantity,
              currentSystemQuantity: c.currentSystemQuantity,
              countedQuantity: c.countedQuantity,
            ),
          )
          .toList();
      final updated = await _localDataSource.markConflict(sessionId, models);
      return updated.toEntity();
    });
  }

  @override
  Future<ApiResult<List<CountSession>>> getSessionsPendingSync() {
    return guardApiCall(() async {
      final models = await _localDataSource.getSessionsPendingSync();
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<ApiResult<void>> recoverInterruptedSyncs() {
    return guardApiCall(() => _localDataSource.recoverInterruptedSyncs());
  }

  @override
  Future<ApiResult<List<ProductConflict>>> getConflicts(String sessionId) {
    return guardApiCall(() async {
      final models = await _localDataSource.getConflicts(sessionId);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<ApiResult<void>> applyConflictResolutions(
    String sessionId,
    Map<int, ConflictResolution> resolutions,
  ) {
    return guardApiCall(() async {
      final conflicts = await _localDataSource.getConflicts(sessionId);
      for (final conflict in conflicts) {
        final resolution =
            resolutions[conflict.productId] ?? ConflictResolution.keepMine;
        final resolvedQuantity = resolution == ConflictResolution.keepMine
            ? conflict.countedQuantity
            : conflict.currentSystemQuantity;

        await _productLocalDataSource.upsertCountedQuantity(
          sessionId: sessionId,
          productId: conflict.productId,
          expectedVersion: conflict.currentVersion,
          countedQuantity: resolvedQuantity,
        );
      }
      await _localDataSource.clearConflicts(sessionId);
    });
  }
}
