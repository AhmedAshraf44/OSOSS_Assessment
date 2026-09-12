import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/core/di/injector.dart';
import 'package:inventory_count_app/core/extensions/navigation_x.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/conflict_review/conflict_review_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/sessions/sessions_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/screens/conflict_review_screen.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/screens/count_sessions_screen.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/screens/product_list_screen.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';

abstract final class InventoryCountNavigator {
  static Future<bool> openSessions(BuildContext context, Store store) async {
    final changed = await context.pushScreen<bool>(
      BlocProvider(
        create: (_) => sl<SessionsCubit>()..load(store.id),
        child: CountSessionsScreen(store: store),
      ),
    );
    return changed ?? false;
  }

  static Future<void> openHistoricalSession(
    BuildContext context,
    Store store,
    CountSession session,
  ) {
    return context.pushScreen<void>(
      BlocProvider(
        create: (_) => sl<ProductListCubit>(),
        child: ProductListScreen(store: store, session: session),
      ),
    );
  }

  static Future<CountSession?> openConflictReview(
    BuildContext context,
    CountSession session,
  ) {
    return context.pushScreen<CountSession>(
      BlocProvider(
        create: (_) => sl<ConflictReviewCubit>()..load(session),
        child: ConflictReviewScreen(session: session),
      ),
    );
  }
}
