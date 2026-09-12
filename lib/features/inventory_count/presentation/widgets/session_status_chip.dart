import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';

/// Compact colored label for a session's status, using the assessment's
/// own status vocabulary.
class SessionStatusChip extends StatelessWidget {
  const SessionStatusChip({super.key, required this.status});

  final CountSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CountSessionStatus.draft => ('Draft', AppColors.textSecondary),
      CountSessionStatus.readyToSubmit => ('Ready to submit', AppColors.pending),
      CountSessionStatus.pendingSync => (
        'Pending synchronization',
        AppColors.pending,
      ),
      CountSessionStatus.syncing => ('Synchronizing', AppColors.pending),
      CountSessionStatus.conflict => ('Conflict', AppColors.danger),
      CountSessionStatus.synced => ('Synchronized', AppColors.success),
      CountSessionStatus.failed => ('Failed', AppColors.danger),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
