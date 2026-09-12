import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/domain/usecases/get_session_progress.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_state.dart';

/// Builds product-list state for a session, reading the count progress
/// that always goes with it.
///
/// Progress is presentation detail, not something the screen can act on:
/// an unreadable progress row shows as zero rather than failing the whole
/// screen, which would hide a perfectly usable product list.
class ProductListStateFactory {
  const ProductListStateFactory(this._getSessionProgress);

  final GetSessionProgress _getSessionProgress;

  Future<ProductListReady> forSession(CountSession session) async {
    return ProductListReady.forSession(
      session,
      await progressFor(session.storeId, session.localId),
    );
  }

  Future<CountProgress> progressFor(int storeId, String sessionId) async {
    final result = await _getSessionProgress(
      storeId: storeId,
      sessionId: sessionId,
    );
    return result.when(
      onSuccess: (progress) => progress,
      onFailure: (_) => CountProgress.zero,
    );
  }
}
