import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_resolution.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/conflict_review_item.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/quantity_stat.dart';

/// One conflicted product: the product identity, the three quantities the
/// assessment requires (original system qty, latest server qty, employee's
/// count), and the employee's keep-mine/use-server choice for it.
class ConflictCard extends StatelessWidget {
  const ConflictCard({
    super.key,
    required this.item,
    required this.resolution,
    required this.onResolutionChanged,
  });

  final ConflictReviewItem item;
  final ConflictResolution resolution;
  final ValueChanged<ConflictResolution> onResolutionChanged;

  @override
  Widget build(BuildContext context) {
    final conflict = item.conflict;
    final product = item.product;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product?.name ?? 'Product #${conflict.productId}',
              style: context.textTheme.titleMedium,
            ),
            if (product != null) ...[
              SizedBox(height: 2.h),
              Text(
                'SKU ${product.sku} · ${product.barcode}',
                style: context.textTheme.bodySmall,
              ),
            ],
            SizedBox(height: 10.h),
            Row(
              children: [
                QuantityStat(
                  label: 'Original',
                  value: conflict.originalSystemQuantity,
                ),
                QuantityStat(
                  label: 'Server now',
                  value: conflict.currentSystemQuantity,
                  color: AppColors.danger,
                ),
                QuantityStat(
                  label: 'Your count',
                  value: conflict.countedQuantity,
                  color: AppColors.accent,
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'Version ${conflict.expectedVersion} -> ${conflict.currentVersion}',
              style: context.textTheme.bodySmall,
            ),
            SizedBox(height: 12.h),
            SegmentedButton<ConflictResolution>(
              segments: const [
                ButtonSegment(
                  value: ConflictResolution.keepMine,
                  label: Text('Keep my count'),
                ),
                ButtonSegment(
                  value: ConflictResolution.acceptServer,
                  label: Text('Use server value'),
                ),
              ],
              selected: {resolution},
              onSelectionChanged: (selection) =>
                  onResolutionChanged(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}
