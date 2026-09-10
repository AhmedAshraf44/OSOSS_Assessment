import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_cubit.dart';
import 'package:inventory_count_app/features/stores/presentation/cubit/store_state.dart';

/// A single selectable store row. Wrapped in its own [BlocSelector] so
/// picking a store only rebuilds the previously- and newly-selected tiles,
/// not the whole list (CLAUDE.md: BlocSelector on the smallest widget).
class StoreTile extends StatelessWidget {
  const StoreTile({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<StoreCubit, StoreState, bool>(
      selector: (state) =>
          state is StoreLoaded && state.selectedStoreId == store.id,
      builder: (context, isSelected) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: () => context.read<StoreCubit>().selectStore(store.id),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(store.name, style: context.textTheme.titleMedium),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.accent : AppColors.border,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
