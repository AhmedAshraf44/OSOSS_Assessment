import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';

/// Shows the count session's current sync status. Draft (nothing submitted
/// yet) renders nothing — there's nothing to report until the employee
/// submits.
class SessionStatusBanner extends StatelessWidget {
  const SessionStatusBanner({
    super.key,
    required this.status,
    required this.attemptCount,
    this.lastError,
    this.onRetry,
    this.onReviewConflict,
  });

  final CountSessionStatus status;
  final int attemptCount;
  final String? lastError;
  final VoidCallback? onRetry;
  final VoidCallback? onReviewConflict;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);
    if (config == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: config.color.withValues(alpha: 0.12),
      child: Row(
        children: [
          if (config.showSpinner)
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(config.color),
              ),
            )
          else
            Icon(config.icon, size: 18.sp, color: config.color),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              config.message,
              style: context.textTheme.bodySmall?.copyWith(
                color: config.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (status == CountSessionStatus.failed && onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          if (status == CountSessionStatus.conflict && onReviewConflict != null)
            TextButton(onPressed: onReviewConflict, child: const Text('Review')),
        ],
      ),
    );
  }

  _BannerConfig? _configFor(CountSessionStatus status) {
    return switch (status) {
      CountSessionStatus.draft => null,
      CountSessionStatus.readyToSubmit => _BannerConfig(
        color: AppColors.pending,
        icon: Icons.hourglass_top,
        message: 'Ready to submit',
      ),
      CountSessionStatus.pendingSync => _BannerConfig(
        color: AppColors.pending,
        icon: Icons.cloud_upload_outlined,
        message: 'Pending synchronization — will sync automatically.',
      ),
      CountSessionStatus.syncing => _BannerConfig(
        color: AppColors.pending,
        icon: Icons.sync,
        message: 'Synchronizing…',
        showSpinner: true,
      ),
      CountSessionStatus.synced => _BannerConfig(
        color: AppColors.success,
        icon: Icons.check_circle_outline,
        message: 'Synchronized with the server.',
      ),
      CountSessionStatus.conflict => const _BannerConfig(
        color: AppColors.danger,
        icon: Icons.warning_amber_outlined,
        message: 'Version conflicts need your review before this can sync.',
      ),
      CountSessionStatus.failed => _BannerConfig(
        color: AppColors.danger,
        icon: Icons.error_outline,
        message: attemptCount > 0
            ? 'Sync failed (attempt $attemptCount)${lastError != null ? ': $lastError' : '.'}'
            : (lastError ?? 'Sync failed.'),
      ),
    };
  }
}

class _BannerConfig {
  const _BannerConfig({
    required this.color,
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  final Color color;
  final IconData icon;
  final String message;
  final bool showSpinner;
}
