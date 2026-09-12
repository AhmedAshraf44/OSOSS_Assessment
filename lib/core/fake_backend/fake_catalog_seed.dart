import 'package:inventory_count_app/core/fake_backend/models/fake_product_record.dart';
import 'package:inventory_count_app/core/fake_backend/models/fake_store_record.dart';

/// The dataset the simulated backend starts from.
abstract final class FakeCatalogSeed {
  static const int productsPerStore = 137;

  static const List<FakeStoreRecord> stores = [
    FakeStoreRecord(id: 1, name: 'Cairo Store'),
    FakeStoreRecord(id: 2, name: 'Alexandria Store'),
    FakeStoreRecord(id: 3, name: 'Giza Store'),
  ];

  static const List<String> _categories = [
    'Scanner',
    'Printer',
    'Cable',
    'Adapter',
    'Battery',
    'Charger',
    'Case',
    'Stand',
    'Mount',
    'Sensor',
  ];

  static List<FakeProductRecord> productsFor(int storeId) {
    final baseId = storeId * 1000 + 100;
    final now = DateTime.now();

    final products = List.generate(productsPerStore, (i) {
      final id = baseId + i;
      return FakeProductRecord(
        id: id,
        name: '${_categories[i % _categories.length]} Model ${_labelFor(i)}',
        sku: 'SKU-$id',
        barcode: '622${id.toString().padLeft(10, '0')}',
        systemQuantity: 5 + (i * 7) % 95,
        version: 1 + (i % 5),
        updatedAt: now.subtract(Duration(hours: i)),
      );
    });

    if (storeId == 1) products[0] = _documentedExampleProduct();
    return products;
  }

  /// Mirrors the assessment's worked example exactly (SCN-101, version 5,
  /// systemQuantity 20) so the conflict demo lines up with the spec.
  static FakeProductRecord _documentedExampleProduct() {
    return FakeProductRecord(
      id: 101,
      name: 'Wireless Barcode Scanner',
      sku: 'SCN-101',
      barcode: '6221234567890',
      systemQuantity: 20,
      version: 5,
      updatedAt: DateTime.parse('2026-09-06T10:00:00Z'),
    );
  }

  static String _labelFor(int index) {
    final letter = String.fromCharCode(65 + (index ~/ 10) % 26);
    return '$letter${index % 10}';
  }
}
