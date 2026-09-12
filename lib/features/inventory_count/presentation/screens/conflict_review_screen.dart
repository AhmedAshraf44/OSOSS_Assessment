import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:inventory_count_app/core/utils/widgets/error_state_view.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/conflict_review/conflict_review_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/conflict_review/conflict_review_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/conflict_review_body.dart';

class ConflictReviewScreen extends StatelessWidget {
  const ConflictReviewScreen({super.key, required this.session});

  final CountSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Conflicts')),
      body: BlocBuilder<ConflictReviewCubit, ConflictReviewState>(
        builder: (context, state) {
          return switch (state) {
            ConflictReviewLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ConflictReviewError(:final failure) => ErrorStateView(
              message: failure.message,
              onRetry: () => context.read<ConflictReviewCubit>().load(session),
            ),
            ConflictReviewLoaded() => ConflictReviewBody(state: state),
          };
        },
      ),
    );
  }
}
