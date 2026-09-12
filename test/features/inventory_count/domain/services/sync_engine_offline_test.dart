import 'package:flutter_test/flutter_test.dart';

import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
import 'package:inventory_count_app/core/utils/id_generator.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/fake_product_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/fake_session_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/count_session_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/product_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/submission_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';

import '../../../../support/test_app_database.dart';

/// End-to-end coverage of the offline → pending → synced / failed flow the
/// assessment's sections 4 and 5 require, driven through the real engine,
/// repositories and simulated backend (no mocks).
void main() {
  late FakeBackend backend;
  late SyncEngine engine;
  late CountSessionRepository sessionRepository;
  late ProductRepository productRepository;

  /// Creates a draft session for store 1 with one counted product.
  Future<CountSession> startCountedSession() async {
    final sessionResult = await sessionRepository.getOrCreateActiveSession(1);
    final session = sessionResult.when(
      onSuccess: (value) => value,
      onFailure: (failure) => throw StateError(failure.message),
    );

    await productRepository.saveCountedQuantity(
      sessionId: session.localId,
      storeId: 1,
      productId: 101,
      countedQuantity: 18,
    );
    return session;
  }

  setUp(() async {
    backend = FakeBackend()..latency = Duration.zero;
    final appDatabase = await createTestAppDatabase();

    final ProductLocalDataSource productLocal = SqfliteProductLocalDataSource(
      appDatabase,
    );
    productRepository = ProductRepositoryImpl(
      remoteDataSource: FakeProductRemoteDataSource(backend),
      localDataSource: productLocal,
    );
    sessionRepository = CountSessionRepositoryImpl(
      localDataSource: SqfliteCountSessionLocalDataSource(appDatabase),
      productLocalDataSource: productLocal,
      idGenerator: const IdGenerator(),
    );
    engine = SyncEngine(
      sessionRepository: sessionRepository,
      submissionRepository: SubmissionRepositoryImpl(
        remoteDataSource: FakeSessionRemoteDataSource(backend),
        productLocalDataSource: productLocal,
      ),
    );

    // The catalog has to exist locally before anything can be counted.
    await productRepository.syncProductsFromServer(1);
  });

  tearDown(() => engine.dispose());

  test(
    'submitting while offline leaves the session pending, not failed, and '
    'does not burn a retry attempt',
    () async {
      final session = await startCountedSession();
      backend.forceOffline = true;

      final result = await engine.submitAndSync(session);

      expect(result.status, CountSessionStatus.pendingSync);
      expect(result.attemptCount, 0);
      expect(result.serverId, isNull);
    },
  );

  test('a pending session syncs automatically once connectivity returns', () async {
    final session = await startCountedSession();
    backend.forceOffline = true;
    final pending = await engine.submitAndSync(session);
    expect(pending.status, CountSessionStatus.pendingSync);

    backend.forceOffline = false;
    await engine.syncAllPending();

    final sessionsStillPending = await sessionRepository
        .getSessionsPendingSync();
    expect(
      sessionsStillPending.when(onSuccess: (s) => s, onFailure: (_) => []),
      isEmpty,
      reason: 'the queued session should have been picked up and synced',
    );
  });

  test('a real server error marks the session failed and is retryable', () async {
    final session = await startCountedSession();
    backend.forceServerError = true;

    final failed = await engine.submitAndSync(session);
    expect(failed.status, CountSessionStatus.failed);
    expect(failed.attemptCount, 1);

    backend.forceServerError = false;
    final retried = await engine.submitAndSync(failed);
    expect(retried.status, CountSessionStatus.synced);
    expect(retried.serverId, isNotNull);
  });

  test('a request timeout is treated as a real failure, not as offline', () async {
    final session = await startCountedSession();
    backend.forceTimeout = true;

    final result = await engine.submitAndSync(session);

    expect(result.status, CountSessionStatus.failed);
    expect(result.attemptCount, 1);
  });

  test(
    'submitting twice reuses the same idempotency key and one server session',
    () async {
      final session = await startCountedSession();

      final first = await engine.submitAndSync(session);
      expect(first.status, CountSessionStatus.synced);

      // A second sync attempt on an already-synced session is a no-op, and
      // the server id must not change (no duplicate submission).
      final second = await engine.syncSession(first);
      expect(second.serverId, first.serverId);
    },
  );

  test('a conflicting submission ends in conflict, never silently synced', () async {
    final session = await startCountedSession();
    // The employee counted against version 5; a sale moves the server on.
    backend.simulateConcurrentSale(storeId: 1, productId: 101);

    final result = await engine.submitAndSync(session);

    expect(result.status, CountSessionStatus.conflict);
    final conflicts = await sessionRepository.getConflicts(session.localId);
    expect(
      conflicts.when(onSuccess: (c) => c, onFailure: (_) => []),
      hasLength(1),
    );
  });

  test(
    'a session interrupted mid-sync is recovered as pending, not stuck',
    () async {
      final session = await startCountedSession();
      // Simulate the app dying while the request was in flight.
      await sessionRepository.updateStatus(
        session.localId,
        CountSessionStatus.syncing,
      );

      await engine.recoverInterruptedSyncs();

      final pending = await sessionRepository.getSessionsPendingSync();
      expect(
        pending
            .when(onSuccess: (s) => s, onFailure: (_) => <CountSession>[])
            .map((s) => s.localId),
        contains(session.localId),
      );
    },
  );
}
