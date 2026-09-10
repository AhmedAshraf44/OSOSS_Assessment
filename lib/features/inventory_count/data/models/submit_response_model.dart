import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/features/inventory_count/data/models/product_conflict_model.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/submit_result.dart';

/// Matches the assessment's submit-response contract:
/// `{ "sessionId": 9001, "status": "accepted" }` or
/// `{ "status": "conflict", "conflicts": [...] }`.
sealed class SubmitResponseModel {
  const SubmitResponseModel();

  factory SubmitResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      final status = json['status'] as String;
      return switch (status) {
        'accepted' => AcceptedResponseModel(json['sessionId'] as int),
        'conflict' => ConflictResponseModel(
          (json['conflicts'] as List<dynamic>)
              .map(
                (c) => ProductConflictModel.fromJson(c as Map<String, dynamic>),
              )
              .toList(),
        ),
        _ => throw const MalformedResponseException(),
      };
    } on TypeError {
      throw const MalformedResponseException();
    }
  }

  SubmitResult toEntity();
}

class AcceptedResponseModel extends SubmitResponseModel {
  const AcceptedResponseModel(this.serverId);

  final int serverId;

  @override
  SubmitResult toEntity() => SubmitAccepted(serverId);
}

class ConflictResponseModel extends SubmitResponseModel {
  const ConflictResponseModel(this.conflicts);

  final List<ProductConflictModel> conflicts;

  @override
  SubmitResult toEntity() =>
      SubmitConflict(conflicts.map((c) => c.toEntity()).toList());
}
