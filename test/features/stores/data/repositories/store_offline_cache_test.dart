import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventory_count_app/core/error/failures.dart';
import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/fake_product_remote_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/sqflite_product_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/repositories/product_repository_impl.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';
import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
import 'package:inventory_count_app/features/stores/data/datasources/fake_store_remote_data_source.dart';
import 'package:inventory_count_app/features/stores/data/datasources/store_local_data_source.dart';
import 'package:inventory_count_app/features/stores/data/repositories/store_repository_impl.dart';
import 'package:inventory_count_app/features/stores/domain/repositories/store_repository.dart';

import '../../../../support/test_app_database.dart';

/// "Downloaded while online stays visible offline" — the first two steps of
/// the offline flow (Select Store -> Download Products) must survive losing
/// connectivity, otherwise the employee can never reach the count they
/// already have on the device.
void main() {
  late FakeBackend backend;
  late StoreRepository storeRepository;
  late ProductRepository productRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackend()..latency = Duration.zero;

    final localDataSource = SharedPrefsStoreLocalDataSource(
      await SharedPreferences.getInstance(),
    );
    storeRepository = StoreRepositoryImpl(
      remoteDataSource: FakeStoreRemoteDataSource(backend),
      localDataSource: localDataSource,
    );

    productRepository = ProductRepositoryImpl(
      remoteDataSource: FakeProductRemoteDataSource(backend),
      localDataSource: SqfliteProductLocalDataSource(
        await createTestAppDatabase(),
      ),
    );
  });

  List<String> namesOf(ApiResult<List<Store>> result) {
    return result.when(
      onSuccess: (stores) => stores.map((store) => store.name).toList(),
      onFailure: (_) => <String>[],
    );
  }

  test('stores downloaded while online are still listed offline', () async {
    final online = await storeRepository.getStores();
    expect(namesOf(online), contains('Cairo Store'));

    backend.forceOffline = true;

    final offline = await storeRepository.getStores();
    expect(
      namesOf(offline),
      namesOf(online),
      reason: 'the cached download must be served when the request fails',
    );
  });

  test(
    'with nothing ever downloaded, being offline is reported as a failure '
    'rather than an empty store list',
    () async {
      backend.forceOffline = true;

      final result = await storeRepository.getStores();

      expect(
        result.when(onSuccess: (_) => null, onFailure: (failure) => failure),
        isA<NetworkFailure>(),
      );
    },
  );

  test(
    'products downloaded while online remain readable offline, for the '
    'store that downloaded them',
    () async {
      await storeRepository.getStores();
      await productRepository.syncProductsFromServer(1);

      backend.forceOffline = true;

      final firstPage = await productRepository.getLocalProductPage(
        storeId: 1,
        sessionId: 'session-1',
        offset: 0,
        limit: 50,
      );
      expect(
        firstPage.when(
          onSuccess: (value) => value.entries.length,
          onFailure: (failure) => throw StateError(failure.message),
        ),
        50,
      );

      // Searching the local catalogue works offline too — this is the
      // documented example product, which sorts too late to be on page 1.
      final searched = await productRepository.getLocalProductPage(
        storeId: 1,
        sessionId: 'session-1',
        offset: 0,
        limit: 50,
        searchQuery: 'SCN-101',
      );
      expect(
        searched.when(
          onSuccess: (value) => value.entries.single.product.name,
          onFailure: (failure) => throw StateError(failure.message),
        ),
        'Wireless Barcode Scanner',
        reason: 'the catalogue on the device is served without the network',
      );
    },
  );
}
