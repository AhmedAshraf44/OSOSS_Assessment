import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/models/count_status_visual.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/status_pill.dart';

/// Identifies one product in the list: name, SKU/barcode, and its system
/// quantity next to the current count status.
class ProductSummary extends StatelessWidget {
  const ProductSummary({
    super.key,
    required this.product,
    required this.status,
    this.hasConflict = false,
  });

  final Product product;
  final CountStatusVisual status;
  final bool hasConflict;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: context.textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Text(
          'SKU ${product.sku}  ·  ${product.barcode}',
          style: context.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: [
            StatusPill(
              label: 'System ${product.systemQuantity}',
              color: AppColors.textSecondary,
            ),
            StatusPill(label: status.label, color: status.color, filled: true),
            if (hasConflict)
              const StatusPill(
                label: 'Conflict',
                color: AppColors.danger,
                filled: true,
              ),
          ],
        ),
      ],
    );
  }
}
