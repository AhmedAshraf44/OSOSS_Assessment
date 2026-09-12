import 'package:flutter/material.dart';

import 'package:inventory_count_app/core/theme/app_colors.dart';

class CountFilterChip extends StatelessWidget {
  const CountFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
