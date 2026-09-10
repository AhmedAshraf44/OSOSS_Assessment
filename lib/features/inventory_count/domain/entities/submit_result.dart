import 'package:equatable/equatable.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/product_conflict.dart';

/// Outcome of a submission that the server actually responded to — as
/// opposed to a [Failure], which means the request itself didn't succeed
/// (network/timeout/server error). A conflict is an expected, valid server
/// response, never something the app silently resolves.
sealed class SubmitResult extends Equatable {
  const SubmitResult();

  @override
  List<Object?> get props => [];
}

final class SubmitAccepted extends SubmitResult {
  const SubmitAccepted(this.serverId);

  final int serverId;

  @override
  List<Object?> get props => [serverId];
}

final class SubmitConflict extends SubmitResult {
  const SubmitConflict(this.conflicts);

  final List<ProductConflict> conflicts;

  @override
  List<Object?> get props => [conflicts];
}
