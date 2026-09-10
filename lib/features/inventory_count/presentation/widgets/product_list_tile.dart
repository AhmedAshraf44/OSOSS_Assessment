import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/extensions/build_context_x.dart';
import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/core/utils/debouncer.dart';
import 'package:inventory_count_app/core/utils/quantity_math.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list_cubit.dart';

/// One product row, as handed to it by `PagedListView`'s item builder.
///
/// Owns its own displayed quantity as local state (updated immediately as
/// the employee types) and persists it through the cubit on a debounce —
/// the page of entries `infinite_scroll_pagination` holds is a snapshot,
/// not something this widget can reach back into and mutate.
class ProductListTile extends StatefulWidget {
  const ProductListTile({super.key, required this.entry});

  final ProductListEntry entry;

  @override
  State<ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends State<ProductListTile> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
  late int? _countedQuantity;

  @override
  void initState() {
    super.initState();
    _countedQuantity = widget.entry.countedQuantity;
    _controller = TextEditingController(text: _countedQuantity?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final parsed = value.trim().isEmpty ? null : int.tryParse(value.trim());
    setState(() => _countedQuantity = parsed);
    _debouncer.run(() {
      if (!mounted) return;
      context.read<ProductListCubit>().updateCountedQuantity(
        productId: widget.entry.product.id,
        countedQuantity: parsed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.entry.product;
    final isCounted = QuantityMath.isCounted(_countedQuantity);
    final difference = QuantityMath.difference(
      systemQuantity: product.systemQuantity,
      countedQuantity: _countedQuantity,
    );

    final Color statusColor;
    final String statusLabel;
    if (!isCounted) {
      statusColor = AppColors.textSecondary;
      statusLabel = 'Not counted';
    } else if (difference == 0) {
      statusColor = AppColors.success;
      statusLabel = 'Matches system';
    } else {
      statusColor = AppColors.warning;
      statusLabel = difference! > 0 ? '+$difference' : '$difference';
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
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
                    'SKU ${product.sku} · ${product.barcode}',
                    style: context.textTheme.bodySmall,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Text(
                        'System: ${product.systemQuantity}',
                        style: context.textTheme.bodySmall,
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            SizedBox(
              width: 84.w,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                decoration: const InputDecoration(isDense: true, hintText: 'Qty'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
