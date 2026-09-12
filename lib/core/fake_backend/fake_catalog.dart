import 'package:inventory_count_app/core/fake_backend/fake_catalog_seed.dart';
import 'package:inventory_count_app/core/fake_backend/models/fake_product_record.dart';
import 'package:inventory_count_app/core/fake_backend/models/fake_store_record.dart';

/// The simulated backend's stored data: stores, their products, and the
/// stock changes that happen server-side while a count is in progress.
class FakeCatalog {
  FakeCatalog()
    : _productsByStore = {
        for (final store in FakeCatalogSeed.stores)
          store.id: FakeCatalogSeed.productsFor(store.id),
      };

  final Map<int, List<FakeProductRecord>> _productsByStore;

  List<FakeStoreRecord> get stores => FakeCatalogSeed.stores;

  List<FakeProductRecord> productsFor(int storeId) =>
      _productsByStore[storeId] ?? const [];

  FakeProductRecord? findProduct(int storeId, int productId) {
    for (final product in productsFor(storeId)) {
      if (product.id == productId) return product;
    }
    return null;
  }

  ({List<FakeProductRecord> items, int totalPages}) page({
    required int storeId,
    required int page,
    required int limit,
  }) {
    final all = productsFor(storeId);
    final start = (page - 1) * limit;
    if (start >= all.length) {
      return (items: const [], totalPages: all.isEmpty ? 1 : (all.length / limit).ceil());
    }
    return (
      items: all.sublist(start, (start + limit).clamp(0, all.length)),
      totalPages: all.isEmpty ? 1 : (all.length / limit).ceil(),
    );
  }

  void applySale({
    required int storeId,
    required int productId,
    required int quantityDelta,
  }) {
    final products = _productsByStore[storeId];
    if (products == null) return;

    final index = products.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    products[index] = products[index].afterSale(quantityDelta);
  }
}
