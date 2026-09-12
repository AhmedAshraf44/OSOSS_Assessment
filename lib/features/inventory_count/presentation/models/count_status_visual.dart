import 'package:flutter/material.dart';

import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/core/utils/quantity_math.dart';

/// How one product's count reads at a glance: not counted, matching the
/// system, or off by a signed difference.
class CountStatusVisual {
  const CountStatusVisual({
    required this.color,
    required this.label,
    required this.isCounted,
  });

  factory CountStatusVisual.forCount({
    required int systemQuantity,
    required int? countedQuantity,
  }) {
    if (!QuantityMath.isCounted(countedQuantity)) {
      return const CountStatusVisual(
        color: AppColors.textSecondary,
        label: 'Not counted',
        isCounted: false,
      );
    }

    final difference = QuantityMath.difference(
      systemQuantity: systemQuantity,
      countedQuantity: countedQuantity,
    )!;

    if (difference == 0) {
      return const CountStatusVisual(
        color: AppColors.success,
        label: 'Matches',
        isCounted: true,
      );
    }

    return CountStatusVisual(
      color: AppColors.warning,
      label: difference > 0 ? '+$difference' : '$difference',
      isCounted: true,
    );
  }

  final Color color;
  final String label;
  final bool isCounted;
}
