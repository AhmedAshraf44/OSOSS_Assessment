import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';

extension CountSessionStatusDb on CountSessionStatus {
  String toDbValue() => name;

  static CountSessionStatus fromDbValue(String value) =>
      CountSessionStatus.values.byName(value);
}

class CountSessionModel {
  const CountSessionModel({
    required this.localId,
    this.serverId,
    required this.storeId,
    required this.employeeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.idempotencyKey,
    this.attemptCount = 0,
    this.lastError,
  });

  final String localId;
  final int? serverId;
  final int storeId;
  final String employeeId;
  final CountSessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String idempotencyKey;
  final int attemptCount;
  final String? lastError;

  factory CountSessionModel.fromDbRow(Map<String, Object?> row) {
    try {
      return CountSessionModel(
        localId: row['local_id']! as String,
        serverId: row['server_id'] as int?,
        storeId: row['store_id']! as int,
        employeeId: row['employee_id']! as String,
        status: CountSessionStatusDb.fromDbValue(row['status']! as String),
        createdAt: DateTime.parse(row['created_at']! as String),
        updatedAt: DateTime.parse(row['updated_at']! as String),
        idempotencyKey: row['idempotency_key']! as String,
        attemptCount: (row['attempt_count'] as int?) ?? 0,
        lastError: row['last_error'] as String?,
      );
    } on TypeError {
      throw const LocalStorageException('Corrupt count_sessions row.');
    }
  }

  Map<String, Object?> toDbMap() => {
    'local_id': localId,
    'server_id': serverId,
    'store_id': storeId,
    'employee_id': employeeId,
    'status': status.toDbValue(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'idempotency_key': idempotencyKey,
    'attempt_count': attemptCount,
    'next_retry_at': null,
    'last_error': lastError,
  };

  CountSession toEntity() => CountSession(
    localId: localId,
    serverId: serverId,
    storeId: storeId,
    employeeId: employeeId,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    idempotencyKey: idempotencyKey,
    attemptCount: attemptCount,
    lastError: lastError,
  );
}
