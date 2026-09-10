import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:inventory_count_app/features/inventory_count/domain/entities/product_count_filter.dart';
import 'package:inventory_count_app/features/inventory_count/presentation/widgets/count_filter_chip.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.controller,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final ProductCountFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ProductCountFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search by name, SKU, or barcode',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CountFilterChip(
                  label: 'All',
                  selected: filter == ProductCountFilter.all,
                  onSelected: () => onFilterChanged(ProductCountFilter.all),
                ),
                SizedBox(width: 8.w),
                CountFilterChip(
                  label: 'Counted',
                  selected: filter == ProductCountFilter.counted,
                  onSelected: () =>
                      onFilterChanged(ProductCountFilter.counted),
                ),
                SizedBox(width: 8.w),
                CountFilterChip(
                  label: 'Not counted',
                  selected: filter == ProductCountFilter.notCounted,
                  onSelected: () =>
                      onFilterChanged(ProductCountFilter.notCounted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
