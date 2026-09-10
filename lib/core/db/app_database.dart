import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:inventory_count_app/core/db/db_tables.dart';
import 'package:inventory_count_app/core/error/exceptions.dart';

/// Owns the single sqflite [Database] instance and its schema.
///
/// Schema decisions worth calling out:
/// - `products` is keyed by (store_id, id) and every query against it is
///   scoped by store_id, so data from different stores can never mix
///   (Functional Requirement 1).
/// - `count_items.counted_quantity` is nullable: NULL means "not counted
///   yet", which must be distinguished from a physical count of 0.
/// - `count_items.expected_version` is captured once, when the employee
///   enters a quantity, and is never re-read from `products` afterwards.
///   That snapshot is what lets the server detect a real conflict instead
///   of the client silently re-syncing against its own latest data.
/// - `count_sessions.idempotency_key` is generated when the session is
///   created and reused on every submit/retry of that same session, which
///   is what makes retries safe.
class AppDatabase {
  // ignore: prefer_initializing_formals
  AppDatabase({Database? testDatabase}) : _testDatabase = testDatabase;

  static const int schemaVersion = 1;

  final Database? _testDatabase;
  Database? _database;

  Future<Database> get database async {
    if (_testDatabase != null) return _testDatabase;
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'inventory_count.db');
      return await openDatabase(
        path,
        version: schemaVersion,
        onCreate: (db, version) => _createSchema(db),
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      );
    } catch (_) {
      throw const LocalStorageException('Could not open the local database.');
    }
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE ${DbTables.products} (
        id INTEGER NOT NULL,
        store_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        sku TEXT NOT NULL,
        barcode TEXT NOT NULL,
        system_quantity INTEGER NOT NULL,
        version INTEGER NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (store_id, id)
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_products_store_name ON ${DbTables.products}(store_id, name)',
    );
    batch.execute(
      'CREATE INDEX idx_products_store_sku ON ${DbTables.products}(store_id, sku)',
    );
    batch.execute(
      'CREATE INDEX idx_products_store_barcode ON ${DbTables.products}(store_id, barcode)',
    );

    batch.execute('''
      CREATE TABLE ${DbTables.countSessions} (
        local_id TEXT PRIMARY KEY,
        server_id INTEGER,
        store_id INTEGER NOT NULL,
        employee_id TEXT NOT NULL,
        status TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        idempotency_key TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at TEXT,
        last_error TEXT
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_sessions_store ON ${DbTables.countSessions}(store_id)',
    );
    batch.execute(
      'CREATE INDEX idx_sessions_sync_status ON ${DbTables.countSessions}(sync_status)',
    );

    batch.execute('''
      CREATE TABLE ${DbTables.countItems} (
        session_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        counted_quantity INTEGER,
        expected_version INTEGER NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (session_id, product_id),
        FOREIGN KEY (session_id) REFERENCES ${DbTables.countSessions}(local_id)
          ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE ${DbTables.syncConflicts} (
        session_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        expected_version INTEGER NOT NULL,
        current_version INTEGER NOT NULL,
        original_system_quantity INTEGER NOT NULL,
        current_system_quantity INTEGER NOT NULL,
        counted_quantity INTEGER NOT NULL,
        resolution TEXT,
        PRIMARY KEY (session_id, product_id),
        FOREIGN KEY (session_id) REFERENCES ${DbTables.countSessions}(local_id)
          ON DELETE CASCADE
      )
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
