import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/models/session_banner_config.dart';

/// Shows the count session's current sync status, plus the one action it
/// allows: retry a failed sync, or review conflicts.
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
    final config = SessionBannerConfig.forStatus(
      status,
      attemptCount: attemptCount,
      lastError: lastError,
    );
    if (config == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: config.color.withValues(alpha: 0.12),
      child: Row(
        children: [
          _Leading(config: config),
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
}

class _Leading extends StatelessWidget {
  const _Leading({required this.config});

  final SessionBannerConfig config;

  @override
  Widget build(BuildContext context) {
    if (!config.showSpinner) {
      return Icon(config.icon, size: 18.sp, color: config.color);
    }

    return SizedBox(
      width: 16.w,
      height: 16.w,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(config.color),
      ),
    );
  }
}
