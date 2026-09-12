import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_progress.dart';

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.progress,
    required this.isSyncing,
    required this.onRefresh,
  });

  final CountProgress progress;
  final bool isSyncing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final ratio = progress.total == 0
        ? 0.0
        : progress.counted / progress.total;
    final percent = (ratio * 100).round();

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48.w,
            height: 48.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 5,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Count progress',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${progress.counted} of ${progress.total} products',
                  style: context.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: IconButton(
              tooltip: 'Refresh from server',
              padding: EdgeInsets.zero,
              onPressed: isSyncing ? null : onRefresh,
              icon: isSyncing
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
