import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/models/count_status_visual.dart';

/// The number box the employee types a counted quantity into. Disabled
/// once the session is no longer a draft.
class CountedQuantityField extends StatelessWidget {
  const CountedQuantityField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.status,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final CountStatusVisual status;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68.w,
      decoration: BoxDecoration(
        color: status.isCounted
            ? status.color.withValues(alpha: 0.06)
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: status.isCounted ? status.color : AppColors.border,
          width: status.isCounted ? 1.4 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: status.isCounted ? status.color : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          filled: false,
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          hintText: '0',
        ),
      ),
    );
  }
}
