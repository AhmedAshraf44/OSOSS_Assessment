import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_state.dart';
import 'package:inventory_count_app/features/stores/presentation/widgets/switch_store_dialog.dart';

/// A single selectable store row. Wrapped in its own [BlocSelector] so
/// picking a store only rebuilds the previously- and newly-selected tiles,
/// not the whole list (CLAUDE.md: BlocSelector on the smallest widget).
class StoreTile extends StatelessWidget {
  const StoreTile({super.key, required this.store});

  final Store store;

  Future<void> _onTap(BuildContext context) async {
    final cubit = context.read<StoreCubit>();

    if (await cubit.isLeavingUnsubmittedCount(store.id)) {
      if (!context.mounted) return;
      if (!await SwitchStoreDialog.show(context, store.name)) return;
    }

    await cubit.selectStore(store.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StoreCubit, StoreState, bool>(
      selector: (state) =>
          state is StoreLoaded && state.selectedStoreId == store.id,
      builder: (context, isSelected) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.05)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 16 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () => _onTap(context),
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Row(
                  children: [
                    Container(
                      width: 46.w,
                      height: 46.w,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        store.name,
                        style: context.textTheme.titleMedium,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        key: ValueKey(isSelected),
                        color: isSelected ? AppColors.accent : AppColors.border,
                        size: 24.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
