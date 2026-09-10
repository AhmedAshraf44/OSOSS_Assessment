import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';

class CountSession extends Equatable {
  const CountSession({
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

  /// Null until the server accepts a submission for this session.
  final int? serverId;
  final int storeId;
  final String employeeId;
  final CountSessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Generated once, at session creation, and reused on every submit/retry
  /// of this session — what makes retries safe (Idempotency-Key header).
  final String idempotencyKey;

  /// Number of sync attempts made so far. Incremented on every failure;
  /// used to cap automatic retries (see SyncEngine).
  final int attemptCount;

  /// Message from the most recent failed sync attempt, if any.
  final String? lastError;

  CountSession copyWith({
    int? serverId,
    CountSessionStatus? status,
    DateTime? updatedAt,
    int? attemptCount,
    String? lastError,
  }) {
    return CountSession(
      localId: localId,
      serverId: serverId ?? this.serverId,
      storeId: storeId,
      employeeId: employeeId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      idempotencyKey: idempotencyKey,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [
    localId,
    serverId,
    storeId,
    employeeId,
    status,
    createdAt,
    updatedAt,
    idempotencyKey,
    attemptCount,
    lastError,
  ];
}
