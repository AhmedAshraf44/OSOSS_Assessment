import 'package:inventory_count_app/core/auth/mock_session.dart';
import 'package:inventory_count_app/core/error/exception_mapper.dart';
import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/core/utils/id_generator.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/count_session_model.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_conflict_model.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/conflict_resolution_applier.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_conflict.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';

class CountSessionRepositoryImpl implements CountSessionRepository {
  CountSessionRepositoryImpl({
    required CountSessionLocalDataSource localDataSource,
    required ProductLocalDataSource productLocalDataSource,
    required IdGenerator idGenerator,
  }) : _localDataSource = localDataSource,
       _idGenerator = idGenerator,
       _conflictResolutionApplier = ConflictResolutionApplier(
         sessionLocalDataSource: localDataSource,
         productLocalDataSource: productLocalDataSource,
       );

  final CountSessionLocalDataSource _localDataSource;
  final IdGenerator _idGenerator;
  final ConflictResolutionApplier _conflictResolutionApplier;

  @override
  Future<ApiResult<CountSession>> getOrCreateActiveSession(int storeId) {
    return guardApiCall(() async {
      final existing = await _localDataSource.getActiveDraftSession(storeId);
      if (existing != null) return existing.toEntity();

      final session = CountSessionModel.newDraft(
        localId: _idGenerator.generate(),
        storeId: storeId,
        employeeId: MockSession.employeeId,
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
    return _session(() => _localDataSource.updateStatus(sessionId, status));
  }

  @override
  Future<ApiResult<CountSession>> markSynced(String sessionId, int serverId) {
    return _session(() => _localDataSource.markSynced(sessionId, serverId));
  }

  @override
  Future<ApiResult<CountSession>> markFailed(
    String sessionId,
    String errorMessage,
  ) {
    return _session(() => _localDataSource.markFailed(sessionId, errorMessage));
  }

  @override
  Future<ApiResult<CountSession>> markPendingRetry(
    String sessionId,
    String reason,
  ) {
    return _session(() => _localDataSource.markPendingRetry(sessionId, reason));
  }

  @override
  Future<ApiResult<CountSession>> markConflict(
    String sessionId,
    List<ProductConflict> conflicts,
  ) {
    return _session(
      () => _localDataSource.markConflict(
        sessionId,
        conflicts.map(ProductConflictModel.fromEntity).toList(),
      ),
    );
  }

  @override
  Future<ApiResult<List<CountSession>>> getSessionsPendingSync() {
    return _sessions(_localDataSource.getSessionsPendingSync);
  }

  @override
  Future<ApiResult<List<CountSession>>> getSessionsForStore(int storeId) {
    return _sessions(() => _localDataSource.getSessionsForStore(storeId));
  }

  @override
  Future<ApiResult<void>> recoverInterruptedSyncs() {
    return guardApiCall(_localDataSource.recoverInterruptedSyncs);
  }

  @override
  Future<ApiResult<List<ProductConflict>>> getConflicts(String sessionId) {
    return guardApiCall(() async {
      final models = await _localDataSource.getConflicts(sessionId);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<ApiResult<void>> applyConflictResolutions(
    String sessionId,
    Map<int, ConflictResolution> resolutions,
  ) {
    return guardApiCall(
      () => _conflictResolutionApplier.apply(sessionId, resolutions),
    );
  }

  Future<ApiResult<CountSession>> _session(
    Future<CountSessionModel> Function() write,
  ) {
    return guardApiCall(() async => (await write()).toEntity());
  }

  Future<ApiResult<List<CountSession>>> _sessions(
    Future<List<CountSessionModel>> Function() read,
  ) {
    return guardApiCall(
      () async => (await read()).map((model) => model.toEntity()).toList(),
    );
  }
}
