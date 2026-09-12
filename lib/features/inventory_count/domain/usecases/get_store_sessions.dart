import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_summary.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';

/// Every session for a store — the draft in progress plus previously
/// submitted ones — each paired with its counted-product progress.
class GetStoreSessions {
  const GetStoreSessions({
    required CountSessionRepository sessionRepository,
    required ProductRepository productRepository,
  }) : _sessionRepository = sessionRepository,
       _productRepository = productRepository;

  final CountSessionRepository _sessionRepository;
  final ProductRepository _productRepository;

  Future<ApiResult<List<CountSessionSummary>>> call(int storeId) async {
    final sessionsResult = await _sessionRepository.getSessionsForStore(
      storeId,
    );

    return sessionsResult.when(
      onSuccess: (sessions) async {
        final progressResult = await _productRepository.getProgressForSessions(
          storeId: storeId,
          sessionIds: sessions.map((s) => s.localId).toList(),
        );
        final progressById = progressResult.when(
          onSuccess: (value) => value,
          onFailure: (_) => const <String, CountProgress>{},
        );

        return ResultSuccess(
          sessions
              .map(
                (session) => CountSessionSummary(
                  session: session,
                  progress:
                      progressById[session.localId] ?? CountProgress.zero,
                ),
              )
              .toList(),
        );
      },
      onFailure: (failure) async => ResultFailure(failure),
    );
  }
}
