import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:inventory_count_app/core/db/app_database.dart';

/// Builds an [AppDatabase] backed by an in-memory sqlite database (via
/// sqflite_common_ffi) with the real production schema applied — used by
/// data-source tests so they exercise actual SQL, not a mock.
Future<AppDatabase> createTestAppDatabase() async {
  sqfliteFfiInit();
  // databaseFactoryFfiNoIsolate — the isolate-backed databaseFactoryFfi
  // talks to its worker isolate over a real async channel, which hangs
  // forever inside a widget test's fake-async zone (tester.pump() never
  // drives real isolate messaging). The no-isolate factory runs sqlite
  // synchronously on the calling isolate instead, which works in both
  // plain `test()` and widget `testWidgets()` tests.
  //
  // singleInstance: false — otherwise sqflite's factory caches and reuses
  // the same in-memory connection across tests (they all use the same
  // ":memory:" path), so the second test's schema creation fails with
  // "table already exists" against the first test's still-open database.
  final db = await databaseFactoryFfiNoIsolate.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
  await AppDatabase.createSchema(db);
  return AppDatabase(testDatabase: db);
}
