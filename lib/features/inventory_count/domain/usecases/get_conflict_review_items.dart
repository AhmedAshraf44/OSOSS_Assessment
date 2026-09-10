import 'package:inventory_count_app/core/result/api_result.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_review_item.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/count_session_repository.dart';
import 'package:inventory_count_app/features/inventory_count/domain/repositories/product_repository.dart';

/// Combines the raw conflicts stored for a session with the matching
/// cached product info, so the review screen can clearly identify each
/// affected product instead of showing a bare id.
class GetConflictReviewItems {
  const GetConflictReviewItems({
    required CountSessionRepository sessionRepository,
    required ProductRepository productRepository,
  }) : _sessionRepository = sessionRepository,
       _productRepository = productRepository;

  final CountSessionRepository _sessionRepository;
  final ProductRepository _productRepository;

  Future<ApiResult<List<ConflictReviewItem>>> call({
    required String sessionId,
    required int storeId,
  }) async {
    final conflictsResult = await _sessionRepository.getConflicts(sessionId);

    return conflictsResult.when(
      onSuccess: (conflicts) async {
        final productsResult = await _productRepository.getProductsByIds(
          storeId: storeId,
          productIds: conflicts.map((c) => c.productId).toList(),
        );
        final productsById = productsResult.when(
          onSuccess: (products) => {for (final p in products) p.id: p},
          onFailure: (_) => const {},
        );

        return ResultSuccess(
          conflicts
              .map(
                (conflict) => ConflictReviewItem(
                  conflict: conflict,
                  product: productsById[conflict.productId],
                ),
              )
              .toList(),
        );
      },
      onFailure: (failure) async => ResultFailure(failure),
    );
  }
}
