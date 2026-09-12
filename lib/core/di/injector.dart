import 'package:inventory_count_app/core/di/injector_dependencies.dart';

final GetIt sl = GetIt.instance;
Future<void> configureDependencies() async {
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<ConnectivityMonitor>(
    () => ConnectivityMonitor(sl()),
  );

  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<IdGenerator>(() => const IdGenerator());

  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  sl.registerLazySingleton<FakeBackend>(
    () => FakeBackend(connectivityMonitor: sl()),
  );

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
    () => StoreCubit(
      getStores: sl(),
      getSelectedStoreId: sl(),
      selectStore: sl(),
      hasUnsubmittedCount: sl(),
    ),
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
    () => CountSessionRepositoryImpl(
      localDataSource: sl(),
      productLocalDataSource: sl(),
      idGenerator: sl(),
    ),
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
  sl.registerFactory(() => WatchSessionUpdates(sl()));
  sl.registerFactory(
    () => GetStoreSessions(sessionRepository: sl(), productRepository: sl()),
  );
  sl.registerFactory(() => HasUnsubmittedCount(sl()));
  sl.registerFactory(
    () => GetConflictReviewItems(
      sessionRepository: sl(),
      productRepository: sl(),
    ),
  );
  sl.registerFactory(() => ResolveConflicts(sl()));
  sl.registerFactory(() => CancelConflictResolution(sl()));

  sl.registerFactory(
    () => ProductListCubit(
      getOrCreateActiveSession: sl(),
      syncProductsFromServer: sl(),
      getLocalProductPage: sl(),
      saveCountedQuantity: sl(),
      getSessionProgress: sl(),
      submitSession: sl(),
      watchSessionUpdates: sl(),
    ),
  );

  sl.registerFactory(
    () => SessionsCubit(getStoreSessions: sl(), getOrCreateActiveSession: sl()),
  );

  sl.registerFactory(
    () => ConflictReviewCubit(
      getConflictReviewItems: sl(),
      resolveConflicts: sl(),
      cancelConflictResolution: sl(),
    ),
  );
}
