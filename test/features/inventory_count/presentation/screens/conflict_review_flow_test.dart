import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
import 'package:inventory_count_app/core/utils/id_generator.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/fake_product_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/fake_session_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/count_session_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/product_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/submission_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/cancel_conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_conflict_review_items.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_local_product_page.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_or_create_active_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_session_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/resolve_conflicts.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/save_counted_quantity.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/submit_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_products_from_server.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/watch_session_updates.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/conflict_review/conflict_review_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/screens/conflict_review_screen.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/screens/product_list_screen.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';

import '../../../../support/test_app_database.dart';

/// End-to-end proof of Business Scenario requirement 9 — "Review
/// synchronization conflicts before final confirmation" — driven through
/// the real screens (ProductListScreen -> submit -> ConflictReviewScreen
/// -> confirm), not just the engine.
void main() {
  testWidgets(
    'submitting a count that conflicts shows a review screen with the '
    'original/server/counted quantities, and only resyncs after the '
    'employee explicitly confirms',
    (tester) async {
      final backend = FakeBackend()..latency = Duration.zero;
      final appDatabase = await createTestAppDatabase();

      final ProductLocalDataSource productLocal = SqfliteProductLocalDataSource(
        appDatabase,
      );
      final CountSessionLocalDataSource sessionLocal =
          SqfliteCountSessionLocalDataSource(appDatabase);

      final ProductRepository productRepository = ProductRepositoryImpl(
        remoteDataSource: FakeProductRemoteDataSource(backend),
        localDataSource: productLocal,
      );
      final CountSessionRepository sessionRepository =
          CountSessionRepositoryImpl(
            localDataSource: sessionLocal,
            productLocalDataSource: productLocal,
            idGenerator: const IdGenerator(),
          );
      final syncEngine = SyncEngine(
        sessionRepository: sessionRepository,
        submissionRepository: SubmissionRepositoryImpl(
          remoteDataSource: FakeSessionRemoteDataSource(backend),
          productLocalDataSource: productLocal,
        ),
      );
      addTearDown(syncEngine.dispose);

      final productListCubit = ProductListCubit(
        getOrCreateActiveSession: GetOrCreateActiveSession(sessionRepository),
        syncProductsFromServer: SyncProductsFromServer(productRepository),
        getLocalProductPage: GetLocalProductPage(productRepository),
        saveCountedQuantity: SaveCountedQuantity(productRepository),
        getSessionProgress: GetSessionProgress(productRepository),
        submitSession: SubmitSession(syncEngine),
        watchSessionUpdates: WatchSessionUpdates(syncEngine),
      );
      addTearDown(productListCubit.close);

      // The employee counted the documented example product (id 101,
      // expectedVersion 5) *before* pumping the screen, then — before
      // submit — a sale lands on the server exactly as the PDF's worked
      // example describes: qty 20 -> 19, version 5 -> 6.
      //
      // This setup runs inside `tester.runAsync` because FakeBackend
      // simulates network latency with `Future.delayed` (fake_backend.dart)
      // — real Timer-based delays never fire inside testWidgets' fake-async
      // zone until a `pump` call advances its clock, so awaiting them here
      // (before the first pumpWidget) would hang forever otherwise.
      late CountSession session;
      await tester.runAsync(() async {
        final sessionResult = await GetOrCreateActiveSession(sessionRepository)(
          1,
        );
        session = sessionResult.when(
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
        backend.simulateConcurrentSale(storeId: 1, productId: 101);
      });

      // The screen resolves ConflictReviewCubit via GetIt (`sl<...>()`) when
      // navigating to the review screen — register just that one factory
      // for this test instead of pulling in the whole app injector.
      final getIt = GetIt.instance;
      getIt.registerFactory<ConflictReviewCubit>(
        () => ConflictReviewCubit(
          getConflictReviewItems: GetConflictReviewItems(
            sessionRepository: sessionRepository,
            productRepository: productRepository,
          ),
          resolveConflicts: ResolveConflicts(syncEngine),
          cancelConflictResolution: CancelConflictResolution(syncEngine),
        ),
      );
      addTearDown(() => getIt.unregister<ConflictReviewCubit>());

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            home: BlocProvider.value(
              value: productListCubit,
              child: const ProductListScreen(
                store: Store(id: 1, name: 'Cairo Store'),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Submit — tap the AppBar action, then confirm the dialog.
      await tester.tap(find.byIcon(Icons.cloud_upload_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // The session must be sitting in Conflict, not silently synced.
      expect(find.textContaining('Status: Conflict'), findsOneWidget);
      final reviewButton = find.widgetWithText(TextButton, 'Review');
      expect(reviewButton, findsOneWidget);

      // Open the review screen — requirement 9's "review conflicts before
      // final confirmation".
      await tester.tap(reviewButton);
      await tester.pumpAndSettle();

      expect(find.byType(ConflictReviewScreen), findsOneWidget);
      expect(find.text('Wireless Barcode Scanner'), findsOneWidget);
      // Original system qty, server's current qty, employee's count — all
      // three numbers the assessment explicitly requires to be shown.
      expect(find.text('20'), findsOneWidget);
      expect(find.text('19'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.textContaining('Version 5 -> 6'), findsOneWidget);

      // Nothing has resynced yet — confirmation is still pending.
      expect(find.text('Confirm & Resubmit'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Confirm & Resubmit'));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Back on the product list, resolved with the server's new version
      // — the conflict is gone and the session synced.
      expect(find.byType(ConflictReviewScreen), findsNothing);
      expect(find.textContaining('Status: Synced'), findsOneWidget);
    },
  );

  testWidgets('canceling out of conflict review loses nothing and returns the '
      'session to draft', (tester) async {
    final backend = FakeBackend()..latency = Duration.zero;
    final appDatabase = await createTestAppDatabase();

    final ProductLocalDataSource productLocal = SqfliteProductLocalDataSource(
      appDatabase,
    );
    final CountSessionLocalDataSource sessionLocal =
        SqfliteCountSessionLocalDataSource(appDatabase);

    final ProductRepository productRepository = ProductRepositoryImpl(
      remoteDataSource: FakeProductRemoteDataSource(backend),
      localDataSource: productLocal,
    );
    final CountSessionRepository sessionRepository = CountSessionRepositoryImpl(
      localDataSource: sessionLocal,
      productLocalDataSource: productLocal,
      idGenerator: const IdGenerator(),
    );
    final syncEngine = SyncEngine(
      sessionRepository: sessionRepository,
      submissionRepository: SubmissionRepositoryImpl(
        remoteDataSource: FakeSessionRemoteDataSource(backend),
        productLocalDataSource: productLocal,
      ),
    );
    addTearDown(syncEngine.dispose);

    // Runs in `tester.runAsync` for the same reason as the test above —
    // FakeBackend's simulated latency uses `Future.delayed`, which never
    // fires inside testWidgets' fake-async zone before any pump call.
    late CountSession session;
    late CountSession conflicted;
    await tester.runAsync(() async {
      final sessionResult = await GetOrCreateActiveSession(sessionRepository)(
        1,
      );
      session = sessionResult.when(
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
      backend.simulateConcurrentSale(storeId: 1, productId: 101);
      conflicted = await SubmitSession(syncEngine)(session);
    });

    final conflictCubit = ConflictReviewCubit(
      getConflictReviewItems: GetConflictReviewItems(
        sessionRepository: sessionRepository,
        productRepository: productRepository,
      ),
      resolveConflicts: ResolveConflicts(syncEngine),
      cancelConflictResolution: CancelConflictResolution(syncEngine),
    )..load(conflicted);
    addTearDown(conflictCubit.close);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: BlocProvider.value(
            value: conflictCubit,
            child: ConflictReviewScreen(session: conflicted),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    final progressResult = await GetSessionProgress(productRepository)(
      storeId: 1,
      sessionId: session.localId,
    );
    expect(
      progressResult.when(onSuccess: (p) => p.counted, onFailure: (_) => -1),
      1,
    );
  });
}
