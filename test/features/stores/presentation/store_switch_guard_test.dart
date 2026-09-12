import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_or_create_active_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_store_sessions.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/has_unsubmitted_count.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/save_counted_quantity.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/submit_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_products_from_server.dart';
import 'package:inventory_count_app/features/stores/data/datasources/fake_store_remote_data_source.dart';
import 'package:inventory_count_app/features/stores/data/datasources/store_local_data_source.dart';
import 'package:inventory_count_app/features/stores/data/repositories/store_repository_impl.dart';
import 'package:inventory_count_app/features/stores/domain/repositories/store_repository.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/get_selected_store_id.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/get_stores.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/select_store.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';

import '../../../support/test_app_database.dart';

/// Functional Requirement 1: "Handle changing stores while an
/// inventory-count session is active." Switching must never happen
/// silently while counted work is still on the device.
void main() {
  late FakeBackend backend;
  late ProductRepository productRepository;
  late CountSessionRepository sessionRepository;
  late SyncEngine syncEngine;
  late StoreCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
    syncEngine = SyncEngine(
      sessionRepository: sessionRepository,
      submissionRepository: SubmissionRepositoryImpl(
        remoteDataSource: FakeSessionRemoteDataSource(backend),
        productLocalDataSource: productLocal,
      ),
    );
    addTearDown(syncEngine.dispose);

    final StoreRepository storeRepository = StoreRepositoryImpl(
      remoteDataSource: FakeStoreRemoteDataSource(backend),
      localDataSource: SharedPrefsStoreLocalDataSource(
        await SharedPreferences.getInstance(),
      ),
    );

    cubit = StoreCubit(
      getStores: GetStores(storeRepository),
      getSelectedStoreId: GetSelectedStoreId(storeRepository),
      selectStore: SelectStore(storeRepository),
      hasUnsubmittedCount: HasUnsubmittedCount(
        GetStoreSessions(
          sessionRepository: sessionRepository,
          productRepository: productRepository,
        ),
      ),
    );
    addTearDown(cubit.close);

    await cubit.loadStores();
  });

  Future<void> countOneProductInStore1() async {
    final sessionResult = await GetOrCreateActiveSession(sessionRepository)(1);
    final session = sessionResult.when(
      onSuccess: (value) => value,
      onFailure: (failure) => throw StateError(failure.message),
    );
    await SyncProductsFromServer(productRepository)(1);
    await SaveCountedQuantity(productRepository)(
      sessionId: session.localId,
      storeId: 1,
      productId: 101,
      countedQuantity: 18,
    );
  }

  test('switching stores is unguarded when nothing has been counted', () async {
    await cubit.selectStore(1);

    expect(await cubit.isLeavingUnsubmittedCount(2), isFalse);
  });

  test(
    'leaving a store that still has an unsynced count asks for confirmation',
    () async {
      await cubit.selectStore(1);
      await countOneProductInStore1();

      expect(await cubit.isLeavingUnsubmittedCount(2), isTrue);
    },
  );

  test('re-picking the store already selected is never a switch', () async {
    await cubit.selectStore(1);
    await countOneProductInStore1();

    expect(await cubit.isLeavingUnsubmittedCount(1), isFalse);
  });

  test(
    'once the count is synced there is nothing left to warn about',
    () async {
      await cubit.selectStore(1);
      await countOneProductInStore1();

      final sessionResult = await GetOrCreateActiveSession(sessionRepository)(1);
      final session = sessionResult.when(
        onSuccess: (value) => value,
        onFailure: (failure) => throw StateError(failure.message),
      );
      await SubmitSession(syncEngine)(session);

      expect(await cubit.isLeavingUnsubmittedCount(2), isFalse);
    },
  );
}
