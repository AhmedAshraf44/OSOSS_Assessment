import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';

/// Simple hero/intro area above the store list — sets context before the
/// employee picks a store.
class StoreListHeader extends StatelessWidget {
  const StoreListHeader({super.key, required this.storeCount});

  final int storeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a store',
            style: context.textTheme.titleLarge?.copyWith(fontSize: 22.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            storeCount == 1
                ? '1 store available for your account'
                : '$storeCount stores available for your account',
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
