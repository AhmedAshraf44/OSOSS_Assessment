import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_summary.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/session_detail_row.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/session_status_chip.dart';

/// One session row showing every field the assessment asks a session to
/// carry: local id, server id (when available), store, created/updated
/// timestamps, employee, status, and counted progress.
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.summary,
    required this.onOpen,
  });

  final CountSessionSummary summary;
  final VoidCallback onOpen;

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final session = summary.session;
    final isDraft = session.status == CountSessionStatus.draft;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDraft ? AppColors.accent : AppColors.border,
          width: isDraft ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SessionStatusChip(status: session.status),
              const Spacer(),
              Text(
                '${summary.progress.counted}/${summary.progress.total} counted',
                style: context.textTheme.bodySmall,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SessionDetailRow(label: 'Local session ID', value: session.localId),
          SessionDetailRow(
            label: 'Server session ID',
            value: session.serverId?.toString() ?? 'Not assigned yet',
          ),
          SessionDetailRow(label: 'Store ID', value: session.storeId.toString()),
          SessionDetailRow(label: 'Employee', value: session.employeeId),
          SessionDetailRow(label: 'Created', value: _formatDateTime(session.createdAt)),
          SessionDetailRow(
            label: 'Last updated',
            value: _formatDateTime(session.updatedAt),
          ),
          if (session.attemptCount > 0)
            SessionDetailRow(
              label: 'Sync attempts',
              value: session.attemptCount.toString(),
            ),
          if (session.lastError != null)
            SessionDetailRow(label: 'Last error', value: session.lastError!),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: isDraft
                ? ElevatedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Resume this count'),
                  )
                : OutlinedButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Open'),
                  ),
          ),
        ],
      ),
    );
  }
}
