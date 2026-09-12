import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/core/theme/app_colors.dart';
import 'package:inventory_count_app/core/utils/debouncer.dart';
import 'package:inventory_count_app/features/inventory_count/domain/entities/product_list_entry.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_cubit.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/cubit/product_list/product_list_state.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/models/count_status_visual.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/counted_quantity_field.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/product_summary.dart';

class ProductListTile extends StatefulWidget {
  const ProductListTile({super.key, required this.entry});

  final ProductListEntry entry;

  @override
  State<ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends State<ProductListTile> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 500),
  );
  late int? _countedQuantity;

  @override
  void initState() {
    super.initState();
    _countedQuantity = widget.entry.countedQuantity;
    _controller = TextEditingController(
      text: _countedQuantity?.toString() ?? '',
    );
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
    final isEditable = context.select<ProductListCubit, bool>((cubit) {
      final state = cubit.state;
      return state is ProductListReady && state.isEditable;
    });

    final product = widget.entry.product;
    final status = CountStatusVisual.forCount(
      systemQuantity: product.systemQuantity,
      countedQuantity: _countedQuantity,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: status.isCounted
              ? status.color.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ProductSummary(
              product: product,
              status: status,
              hasConflict: widget.entry.hasConflict,
            ),
          ),
          SizedBox(width: 12.w),
          CountedQuantityField(
            controller: _controller,
            focusNode: _focusNode,
            status: status,
            enabled: isEditable,
            onChanged: _onChanged,
          ),
        ],
      ),
    );
  }
}
