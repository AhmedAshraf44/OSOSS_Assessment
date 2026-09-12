import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/core/error/failures.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_summary.dart';

sealed class SessionsState extends Equatable {
  const SessionsState();

  @override
  List<Object?> get props => [];
}

final class SessionsLoading extends SessionsState {
  const SessionsLoading();
}

final class SessionsError extends SessionsState {
  const SessionsError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class SessionsLoaded extends SessionsState {
  const SessionsLoaded(this.summaries);

  final List<CountSessionSummary> summaries;

  @override
  List<Object?> get props => [summaries];
}
