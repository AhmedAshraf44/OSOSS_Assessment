import 'package:sqflite/sqflite.dart';

import 'package:inventory_count_app/core/db/app_database.dart';
import 'package:inventory_count_app/core/db/db_tables.dart';
import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/features/inventory_count/data/datasources/count_session_local_data_source.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/count_session_model.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_conflict_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';

class SqfliteCountSessionLocalDataSource implements CountSessionLocalDataSource {
  const SqfliteCountSessionLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<CountSessionModel?> getActiveDraftSession(int storeId) async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbTables.countSessions,
        where: 'store_id = ? AND status = ?',
        whereArgs: [storeId, CountSessionStatus.draft.toDbValue()],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return CountSessionModel.fromDbRow(rows.first);
    } catch (_) {
      throw const LocalStorageException('Could not read the active session.');
    }
  }

  @override
  Future<void> insertSession(CountSessionModel session) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(DbTables.countSessions, session.toDbMap());
    } catch (_) {
      throw const LocalStorageException('Could not create a new session.');
    }
  }

  @override
  Future<CountSessionModel> updateStatus(
    String sessionId,
    CountSessionStatus status,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DbTables.countSessions,
        {
          'status': status.toDbValue(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'local_id = ?',
        whereArgs: [sessionId],
      );
      return _getByIdOrThrow(db, sessionId);
    } catch (_) {
      throw const LocalStorageException('Could not update the session status.');
    }
  }

  @override
  Future<CountSessionModel> markSynced(String sessionId, int serverId) async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DbTables.countSessions,
        {
          'status': CountSessionStatus.synced.toDbValue(),
          'server_id': serverId,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'local_id = ?',
        whereArgs: [sessionId],
      );
      return _getByIdOrThrow(db, sessionId);
    } catch (_) {
      throw const LocalStorageException('Could not mark the session synced.');
    }
  }

  @override
  Future<CountSessionModel> markFailed(
    String sessionId,
    String errorMessage,
  ) async {
    try {
      final db = await _appDatabase.database;
      await db.rawUpdate(
        '''
        UPDATE ${DbTables.countSessions}
        SET status = ?, last_error = ?, attempt_count = attempt_count + 1,
            updated_at = ?
        WHERE local_id = ?
        ''',
        [
          CountSessionStatus.failed.toDbValue(),
          errorMessage,
          DateTime.now().toIso8601String(),
          sessionId,
        ],
      );
      return _getByIdOrThrow(db, sessionId);
    } catch (_) {
      throw const LocalStorageException('Could not mark the session failed.');
    }
  }

  @override
  Future<CountSessionModel> markConflict(
    String sessionId,
    List<ProductConflictModel> conflicts,
  ) async {
    try {
      final db = await _appDatabase.database;
      final batch = db.batch();
      batch.update(
        DbTables.countSessions,
        {
          'status': CountSessionStatus.conflict.toDbValue(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'local_id = ?',
        whereArgs: [sessionId],
      );
      batch.delete(
        DbTables.syncConflicts,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      for (final conflict in conflicts) {
        batch.insert(DbTables.syncConflicts, conflict.toDbMap(sessionId));
      }
      await batch.commit(noResult: true);
      return _getByIdOrThrow(db, sessionId);
    } catch (_) {
      throw const LocalStorageException('Could not save the conflict.');
    }
  }

  @override
  Future<List<CountSessionModel>> getSessionsPendingSync() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbTables.countSessions,
        where: 'status = ?',
        whereArgs: [CountSessionStatus.pendingSync.toDbValue()],
        orderBy: 'updated_at ASC',
      );
      return rows.map(CountSessionModel.fromDbRow).toList();
    } catch (_) {
      throw const LocalStorageException('Could not read pending sessions.');
    }
  }

  @override
  Future<void> recoverInterruptedSyncs() async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DbTables.countSessions,
        {
          'status': CountSessionStatus.pendingSync.toDbValue(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'status = ?',
        whereArgs: [CountSessionStatus.syncing.toDbValue()],
      );
    } catch (_) {
      throw const LocalStorageException('Could not recover interrupted syncs.');
    }
  }

  Future<CountSessionModel> _getByIdOrThrow(Database db, String sessionId) async {
    final rows = await db.query(
      DbTables.countSessions,
      where: 'local_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const LocalStorageException('Session not found after update.');
    }
    return CountSessionModel.fromDbRow(rows.first);
  }
}
