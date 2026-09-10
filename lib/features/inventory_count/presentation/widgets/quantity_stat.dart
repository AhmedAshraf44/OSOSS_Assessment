import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';

/// A single labeled quantity figure — used to lay the three numbers a
/// conflict card must show (original / server now / your count) side by
/// side.
class QuantityStat extends StatelessWidget {
  const QuantityStat({super.key, required this.label, required this.value, this.color});

  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.textTheme.bodySmall),
          SizedBox(height: 2.h),
          Text(
            '$value',
            style: context.textTheme.titleMedium?.copyWith(
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
