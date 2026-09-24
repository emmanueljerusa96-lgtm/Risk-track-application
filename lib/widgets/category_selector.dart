import 'package:flutter/material.dart';

import '../utils/constants.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key, required this.selected,
    required this.onSelected});
  final RiskCategory? selected;
  final ValueChanged<RiskCategory> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8, runSpacing: 5,
        children: RiskCategory.values.map((category) => ChoiceChip(
          avatar: Icon(category.icon, size: 16,
            color: selected == category ? Colors.white : category.color),
          label: Text(category.label),
          selected: selected == category,
          selectedColor: AppColors.teal,
          labelStyle: TextStyle(fontSize: 12, color: selected == category
              ? Colors.white : AppColors.ink),
          onSelected: (_) => onSelected(category),
        )).toList(),
      );
}
