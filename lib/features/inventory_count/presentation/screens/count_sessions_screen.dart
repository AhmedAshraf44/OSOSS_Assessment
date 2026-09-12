import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/core/extensions/navigation_x.dart';
import 'package:inventory_count_app/core/utils/widgets/error_state_view.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_summary.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/sessions/sessions_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/sessions/sessions_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/navigation/inventory_count_navigator.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/sessions_list_view.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';

/// Count sessions for one store: the draft in progress and every
/// previously submitted session, each with its full record (ids, dates,
/// employee, status, progress).
class CountSessionsScreen extends StatelessWidget {
  const CountSessionsScreen({super.key, required this.store});

  final Store store;

  /// The draft is the count the employee is actively working on, so
  /// opening it simply returns to the counting screen. Any other session
  /// is history — it opens read-only instead of silently swapping the list
  /// underneath the current count.
  void _openSession(BuildContext context, CountSessionSummary summary) {
    if (summary.session.status == CountSessionStatus.draft) {
      context.pop(true);
      return;
    }

    InventoryCountNavigator.openHistoricalSession(
      context,
      store,
      summary.session,
    );
  }

  Future<void> _startOrResume(BuildContext context) async {
    final navigator = context.navigator;
    await context.read<SessionsCubit>().startOrResume(store.id);
    navigator.popIfMounted(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${store.name} — Sessions')),
      body: BlocBuilder<SessionsCubit, SessionsState>(
        builder: (context, state) {
          return switch (state) {
            SessionsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SessionsError(:final failure) => ErrorStateView(
              message: failure.message,
              onRetry: () => context.read<SessionsCubit>().load(store.id),
            ),
            SessionsLoaded(:final summaries) => SessionsListView(
              summaries: summaries,
              onOpenSession: (summary) => _openSession(context, summary),
              onStartOrResume: () => _startOrResume(context),
            ),
          };
        },
      ),
    );
  }
}
