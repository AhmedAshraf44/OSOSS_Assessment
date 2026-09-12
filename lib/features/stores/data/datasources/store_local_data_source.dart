import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/features/stores/data/models/store_model.dart';

/// Throws [LocalStorageException] on failure.
abstract interface class StoreLocalDataSource {
  Future<int?> getSelectedStoreId();
  Future<void> setSelectedStoreId(int storeId);

  /// The stores from the last successful download — what the app falls back
  /// to when it opens offline. Empty when nothing has ever been downloaded.
  Future<List<StoreModel>> getCachedStores();
  Future<void> cacheStores(List<StoreModel> stores);
}

class SharedPrefsStoreLocalDataSource implements StoreLocalDataSource {
  const SharedPrefsStoreLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _selectedStoreIdKey = 'selected_store_id';
  static const _cachedStoresKey = 'cached_stores';

  @override
  Future<int?> getSelectedStoreId() async {
    try {
      return _prefs.getInt(_selectedStoreIdKey);
    } catch (_) {
      throw const LocalStorageException();
    }
  }

  @override
  Future<void> setSelectedStoreId(int storeId) async {
    try {
      await _prefs.setInt(_selectedStoreIdKey, storeId);
    } catch (_) {
      throw const LocalStorageException();
    }
  }

  @override
  Future<List<StoreModel>> getCachedStores() async {
    final raw = _prefs.getString(_cachedStoresKey);
    if (raw == null) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => StoreModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // A corrupt cache is not worth failing over — treat it as "nothing
      // downloaded yet" so the app still reaches the network path.
      return const [];
    }
  }

  @override
  Future<void> cacheStores(List<StoreModel> stores) async {
    try {
      await _prefs.setString(
        _cachedStoresKey,
        jsonEncode(stores.map((store) => store.toJson()).toList()),
      );
    } catch (_) {
      throw const LocalStorageException();
    }
  }
}
