import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/submit_result.dart';

abstract interface class SubmissionRepository {
  /// Submits [session]'s counted items using its idempotency key. Only
  /// items with a non-null counted quantity are included — "not counted"
  /// is never sent as a zero count.
  ///
  /// A version conflict is a normal, successful response from the server's
  /// point of view — it comes back as [SubmitConflict], not a [Failure].
  Future<ApiResult<SubmitResult>> submit(CountSession session);
}
