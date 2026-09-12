import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

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
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/services/sync_engine.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_local_product_page.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_or_create_active_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_session_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/save_counted_quantity.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/submit_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/sync_products_from_server.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/watch_session_updates.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/screens/product_list_screen.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';

import '../../../../support/test_app_database.dart';

void main() {
  Future<ProductListCubit> buildCubit() async {
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

    return ProductListCubit(
      getOrCreateActiveSession: GetOrCreateActiveSession(sessionRepository),
      syncProductsFromServer: SyncProductsFromServer(productRepository),
      getLocalProductPage: GetLocalProductPage(productRepository),
      saveCountedQuantity: SaveCountedQuantity(productRepository),
      getSessionProgress: GetSessionProgress(productRepository),
      submitSession: SubmitSession(syncEngine),
      watchSessionUpdates: WatchSessionUpdates(syncEngine),
    );
  }

  Widget buildScreen(ProductListCubit cubit) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const ProductListScreen(
            store: Store(id: 1, name: 'Cairo Store'),
          ),
        ),
      ),
    );
  }

  testWidgets('searching finds a product that sorts past the first page', (
    tester,
  ) async {
    final cubit = await buildCubit();
    await tester.pumpWidget(buildScreen(cubit));

    // Let the initial catalog sync + first page load settle.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    await tester.enterText(find.byType(TextField).first, 'Wireless');
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('Wireless Barcode Scanner'), findsOneWidget);
    expect(
      find.text('No products found. Try adjusting your search or filter.'),
      findsNothing,
    );
  });

  testWidgets(
    'clearing a search restores the full list instead of staying stuck on a partial page',
    (tester) async {
      final cubit = await buildCubit();
      await tester.pumpWidget(buildScreen(cubit));

      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      await tester.enterText(find.byType(TextField).first, 'Wireless');
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('Wireless Barcode Scanner'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '');
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Back to the unfiltered view: the single search match should no
      // longer be the only visible row.
      expect(
        find.text('No products found. Try adjusting your search or filter.'),
        findsNothing,
      );
      expect(find.textContaining('of 137 products'), findsOneWidget);
    },
  );
}
