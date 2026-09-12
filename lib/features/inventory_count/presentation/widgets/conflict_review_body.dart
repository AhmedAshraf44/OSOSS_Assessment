import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/navigation_x.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/conflict_review/conflict_review_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/conflict_review/conflict_review_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/conflict_card.dart';

/// The loaded state's body: one [ConflictCard] per conflict plus a bottom
/// action bar. Pops the screen with the session the confirm/cancel action
/// produced — the caller (ProductListScreen) is responsible for reflecting
/// that fresh status, this widget only drives the local review flow.
class ConflictReviewBody extends StatelessWidget {
  const ConflictReviewBody({super.key, required this.state});

  final ConflictReviewLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              final productId = item.conflict.productId;
              return ConflictCard(
                item: item,
                resolution: state.resolutions[productId]!,
                onResolutionChanged: (resolution) => context
                    .read<ConflictReviewCubit>()
                    .setResolution(productId, resolution),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () => _cancel(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () => _confirm(context),
                    child: state.isSubmitting
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Confirm & Resubmit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final cubit = context.read<ConflictReviewCubit>();
    final navigator = context.navigator;
    navigator.popIfMounted(await cubit.confirmAndResubmit());
  }

  Future<void> _cancel(BuildContext context) async {
    final cubit = context.read<ConflictReviewCubit>();
    final navigator = context.navigator;
    navigator.popIfMounted(await cubit.cancel());
  }
}
