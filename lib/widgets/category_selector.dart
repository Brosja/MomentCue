import 'package:flutter/material.dart';

import '../models/check.dart';
import '../utils/app_theme.dart';

class CategorySelector extends StatelessWidget {
  final CheckCategory selectedCategory;
  final Function(CheckCategory) onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: CheckCategory.values.map((category) {
        final isSelected = category == selectedCategory;
        final categoryInfo = _getCategoryInfo(category);
        
        return InkWell(
          onTap: () => onCategorySelected(category),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  categoryInfo['icon'] as IconData,
                  size: 20,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  categoryInfo['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _getCategoryInfo(CheckCategory category) {
    switch (category) {
      case CheckCategory.hydration:
        return {
          'name': 'Hydration',
          'icon': Icons.water_drop,
        };
      case CheckCategory.posture:
        return {
          'name': 'Posture',
          'icon': Icons.accessibility_new,
        };
      case CheckCategory.medication:
        return {
          'name': 'Medication',
          'icon': Icons.medication,
        };
      case CheckCategory.screenBreak:
        return {
          'name': 'Screen Break',
          'icon': Icons.remove_red_eye,
        };
      case CheckCategory.breathing:
        return {
          'name': 'Breathing',
          'icon': Icons.air,
        };
      case CheckCategory.exercise:
        return {
          'name': 'Exercise',
          'icon': Icons.fitness_center,
        };
      case CheckCategory.custom:
        return {
          'name': 'Custom',
          'icon': Icons.star,
        };
    }
  }
}
