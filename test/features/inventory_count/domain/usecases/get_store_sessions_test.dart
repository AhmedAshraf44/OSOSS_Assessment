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
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_summary.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_store_sessions.dart';

import '../../../../support/test_app_database.dart';

/// Covers the assessment's "Inventory-Count Sessions" requirements: start
/// a session, resume the draft, see its progress, and view previously
/// submitted sessions with their full record.
void main() {
  late FakeBackend backend;
  late SyncEngine engine;
  late CountSessionRepository sessionRepository;
  late ProductRepository productRepository;
  late GetStoreSessions getStoreSessions;

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
    getStoreSessions = GetStoreSessions(
      sessionRepository: sessionRepository,
      productRepository: productRepository,
    );

    await productRepository.syncProductsFromServer(1);
  });

  tearDown(() => engine.dispose());

  Future<List<CountSessionSummary>> loadSummaries() async {
    final result = await getStoreSessions(1);
    return result.when(
      onSuccess: (value) => value,
      onFailure: (failure) => throw StateError(failure.message),
    );
  }

  test('a started session carries every field a session must contain', () async {
    final created = await sessionRepository.getOrCreateActiveSession(1);
    final session = created.when(
      onSuccess: (value) => value,
      onFailure: (f) => throw StateError(f.message),
    );

    final summaries = await loadSummaries();
    expect(summaries, hasLength(1));

    final stored = summaries.single.session;
    expect(stored.localId, session.localId);
    expect(stored.localId, isNotEmpty);
    expect(stored.serverId, isNull, reason: 'not submitted yet');
    expect(stored.storeId, 1);
    expect(stored.employeeId, isNotEmpty);
    expect(stored.status, CountSessionStatus.draft);
    expect(stored.idempotencyKey, isNotEmpty);
    expect(stored.createdAt, isA<DateTime>());
    expect(stored.updatedAt, isA<DateTime>());
  });

  test('resuming returns the same draft instead of starting a second one', () async {
    final first = await sessionRepository.getOrCreateActiveSession(1);
    final second = await sessionRepository.getOrCreateActiveSession(1);

    expect(
      second.when(onSuccess: (s) => s.localId, onFailure: (_) => null),
      first.when(onSuccess: (s) => s.localId, onFailure: (_) => null),
    );
    expect(await loadSummaries(), hasLength(1));
  });

  test('session progress reflects how many products were counted', () async {
    final created = await sessionRepository.getOrCreateActiveSession(1);
    final session = created.when(
      onSuccess: (value) => value,
      onFailure: (f) => throw StateError(f.message),
    );

    await productRepository.saveCountedQuantity(
      sessionId: session.localId,
      storeId: 1,
      productId: 101,
      countedQuantity: 18,
    );

    final summary = (await loadSummaries()).single;
    expect(summary.progress.counted, 1);
    expect(summary.progress.total, greaterThan(1));
  });

  test(
    'a submitted session stays visible in history with its server id, and a '
    'new count starts as a separate session',
    () async {
      final created = await sessionRepository.getOrCreateActiveSession(1);
      final session = created.when(
        onSuccess: (value) => value,
        onFailure: (f) => throw StateError(f.message),
      );
      await productRepository.saveCountedQuantity(
        sessionId: session.localId,
        storeId: 1,
        productId: 101,
        countedQuantity: 18,
      );

      final synced = await engine.submitAndSync(session);
      expect(synced.status, CountSessionStatus.synced);
      expect(synced.serverId, isNotNull);

      // Starting the next count creates a second session; the submitted
      // one remains in the list (that's the "previously submitted
      // sessions" view).
      await sessionRepository.getOrCreateActiveSession(1);

      final summaries = await loadSummaries();
      expect(summaries, hasLength(2));
      expect(
        summaries.map((s) => s.session.status),
        containsAll([CountSessionStatus.draft, CountSessionStatus.synced]),
      );

      final submitted = summaries.firstWhere(
        (s) => s.session.status == CountSessionStatus.synced,
      );
      expect(submitted.session.serverId, synced.serverId);
      expect(submitted.progress.counted, 1);
    },
  );
}
