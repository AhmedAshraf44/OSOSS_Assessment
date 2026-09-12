import 'package:flutter/material.dart';

import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';

/// How each session status is presented in the status banner.
class SessionBannerConfig {
  const SessionBannerConfig({
    required this.color,
    required this.icon,
    required this.message,
    this.showSpinner = false,
  });

  /// Null for a draft — there is nothing to report until the employee
  /// submits.
  static SessionBannerConfig? forStatus(
    CountSessionStatus status, {
    required int attemptCount,
    String? lastError,
  }) {
    return switch (status) {
      CountSessionStatus.draft => null,
      CountSessionStatus.readyToSubmit => const SessionBannerConfig(
        color: AppColors.pending,
        icon: Icons.hourglass_top,
        message: 'Status: Ready to submit',
      ),
      CountSessionStatus.pendingSync => _pendingSync(lastError),
      CountSessionStatus.syncing => const SessionBannerConfig(
        color: AppColors.pending,
        icon: Icons.sync,
        message: 'Status: Synchronizing…',
        showSpinner: true,
      ),
      CountSessionStatus.synced => const SessionBannerConfig(
        color: AppColors.success,
        icon: Icons.check_circle_outline,
        message: 'Status: Synced with the server.',
      ),
      CountSessionStatus.conflict => const SessionBannerConfig(
        color: AppColors.danger,
        icon: Icons.warning_amber_outlined,
        message:
            'Status: Conflict — version conflicts need your review before '
            'this can sync.',
      ),
      CountSessionStatus.failed => _failed(attemptCount, lastError),
    };
  }

  /// A [lastError] here means the request never left the device, so the
  /// banner says why and that it will sync itself later.
  static SessionBannerConfig _pendingSync(String? lastError) {
    return SessionBannerConfig(
      color: AppColors.pending,
      icon: lastError == null
          ? Icons.cloud_upload_outlined
          : Icons.cloud_off_outlined,
      message: lastError == null
          ? 'Status: Pending synchronization — saved on this device, not on '
                'the server yet.'
          : 'Status: Pending synchronization — $lastError Saved on this '
                'device; it will sync automatically once you are back '
                'online.',
    );
  }

  static SessionBannerConfig _failed(int attemptCount, String? lastError) {
    final attempt = attemptCount > 0 ? ' (attempt $attemptCount)' : '';
    final reason = lastError != null ? ': $lastError' : '.';

    return SessionBannerConfig(
      color: AppColors.danger,
      icon: Icons.error_outline,
      message: 'Status: Failed$attempt$reason',
    );
  }

  final Color color;
  final IconData icon;
  final String message;
  final bool showSpinner;
}
