import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventory_count_app/core/db/app_database.dart';
import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
import 'package:inventory_count_app/core/network/connectivity_monitor.dart';
import 'package:inventory_count_app/core/utils/id_generator.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/fake_product_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/fake_session_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/session_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/count_session_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/product_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/submission_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/submission_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_local_product_page.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_or_create_active_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_session_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/recover_interrupted_syncs.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/save_counted_quantity.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/submit_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_pending_sessions.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_products_from_server.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list_cubit.dart';
import 'package:inventory_count_app/features/stores/data/datasources/fake_store_remote_data_source.dart';
import 'package:inventory_count_app/features/stores/data/datasources/store_local_data_source.dart';
import 'package:inventory_count_app/features/stores/data/datasources/store_remote_data_source.dart';
import 'package:inventory_count_app/features/stores/data/repositories/store_repository_impl.dart';
import 'package:inventory_count_app/features/stores/domain/repositories/store_repository.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/get_selected_store_id.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/get_stores.dart';
import 'package:inventory_count_app/features/stores/domain/usecases/select_store.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';

final GetIt sl = GetIt.instance;

/// Registers every injectable dependency. Called once from `main()` before
/// `runApp`. Feature modules register through this same file — Cubits, use
/// cases, and repositories are always resolved via [sl], never instantiated
/// manually in widgets (CLAUDE.md: single core/di/ setup file).
Future<void> configureDependencies() async {
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<ConnectivityMonitor>(() => ConnectivityMonitor(sl()));

  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<IdGenerator>(() => const IdGenerator());

  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  sl.registerLazySingleton<FakeBackend>(() => FakeBackend());

  _registerStoresFeature();
  _registerInventoryCountFeature();
}

void _registerStoresFeature() {
  sl.registerLazySingleton<StoreRemoteDataSource>(
    () => FakeStoreRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<StoreLocalDataSource>(
    () => SharedPrefsStoreLocalDataSource(sl()),
  );
  sl.registerLazySingleton<StoreRepository>(
    () => StoreRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  sl.registerFactory(() => GetStores(sl()));
  sl.registerFactory(() => GetSelectedStoreId(sl()));
  sl.registerFactory(() => SelectStore(sl()));

  sl.registerFactory(
    () =>
        StoreCubit(getStores: sl(), getSelectedStoreId: sl(), selectStore: sl()),
  );
}

void _registerInventoryCountFeature() {
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => FakeProductRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => SqfliteProductLocalDataSource(sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  sl.registerLazySingleton<CountSessionLocalDataSource>(
    () => SqfliteCountSessionLocalDataSource(sl()),
  );
  sl.registerLazySingleton<CountSessionRepository>(
    () => CountSessionRepositoryImpl(localDataSource: sl(), idGenerator: sl()),
  );

  sl.registerLazySingleton<SessionRemoteDataSource>(
    () => FakeSessionRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<SubmissionRepository>(
    () => SubmissionRepositoryImpl(
      remoteDataSource: sl(),
      productLocalDataSource: sl(),
    ),
  );

  // Singleton: its single-flight guard and any in-flight sync state must
  // be shared by every trigger (submit button, connectivity restore, app
  // resume) — not re-created per screen.
  sl.registerLazySingleton<SyncEngine>(
    () => SyncEngine(sessionRepository: sl(), submissionRepository: sl()),
  );

  sl.registerFactory(() => GetOrCreateActiveSession(sl()));
  sl.registerFactory(() => SyncProductsFromServer(sl()));
  sl.registerFactory(() => GetLocalProductPage(sl()));
  sl.registerFactory(() => SaveCountedQuantity(sl()));
  sl.registerFactory(() => GetSessionProgress(sl()));
  sl.registerFactory(() => SubmitSession(sl()));
  sl.registerFactory(() => SyncPendingSessions(sl()));
  sl.registerFactory(() => RecoverInterruptedSyncs(sl()));

  sl.registerFactory(
    () => ProductListCubit(
      getOrCreateActiveSession: sl(),
      syncProductsFromServer: sl(),
      getLocalProductPage: sl(),
      saveCountedQuantity: sl(),
      getSessionProgress: sl(),
      submitSession: sl(),
    ),
  );
}
