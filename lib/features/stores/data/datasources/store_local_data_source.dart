import 'package:shared_preferences/shared_preferences.dart';

import 'package:inventory_count_app/core/error/exceptions.dart';

/// Throws [LocalStorageException] on failure.
abstract interface class StoreLocalDataSource {
  Future<int?> getSelectedStoreId();
  Future<void> setSelectedStoreId(int storeId);
}

class SharedPrefsStoreLocalDataSource implements StoreLocalDataSource {
  const SharedPrefsStoreLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _selectedStoreIdKey = 'selected_store_id';

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
}
