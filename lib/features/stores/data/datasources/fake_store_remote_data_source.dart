import 'package:inventory_count_app/core/fake_backend/fake_backend.dart';
import 'package:inventory_count_app/features/stores/data/datasources/store_remote_data_source.dart';
import 'package:inventory_count_app/features/stores/data/models/store_model.dart';

class FakeStoreRemoteDataSource implements StoreRemoteDataSource {
  const FakeStoreRemoteDataSource(this._backend);

  final FakeBackend _backend;

  @override
  Future<List<StoreModel>> getStores() async {
    final json = await _backend.fetchStores();
    return json.map(StoreModel.fromJson).toList();
  }
}
