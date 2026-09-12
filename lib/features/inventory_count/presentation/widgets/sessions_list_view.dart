import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/core/utils/widgets/empty_state_view.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_status.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/count_session_summary.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/session_card.dart';

/// The loaded sessions list plus the start/resume action. Only one active
/// (draft) session per store is allowed, so the bottom action either
/// resumes the existing draft or starts a fresh count when there is none.
class SessionsListView extends StatelessWidget {
  const SessionsListView({
    super.key,
    required this.summaries,
    required this.onOpenSession,
    required this.onStartOrResume,
  });

  final List<CountSessionSummary> summaries;
  final ValueChanged<CountSessionSummary> onOpenSession;
  final VoidCallback onStartOrResume;

  @override
  Widget build(BuildContext context) {
    final hasDraft = summaries.any(
      (s) => s.session.status == CountSessionStatus.draft,
    );

    return Column(
      children: [
        Expanded(
          child: summaries.isEmpty
              ? const EmptyStateView(
                  icon: Icons.assignment_outlined,
                  message:
                      'No count sessions yet for this store. Start one to '
                      'begin counting.',
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  itemCount: summaries.length,
                  itemBuilder: (context, index) => SessionCard(
                    summary: summaries[index],
                    onOpen: () => onOpenSession(summaries[index]),
                  ),
                ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: onStartOrResume,
                  icon: Icon(
                    hasDraft ? Icons.play_arrow_rounded : Icons.add_rounded,
                  ),
                  label: Text(
                    hasDraft ? 'Resume draft count' : 'Start a new count',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
