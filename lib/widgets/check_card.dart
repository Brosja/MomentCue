import 'package:flutter/material.dart';

import '../models/check.dart';
import '../utils/app_theme.dart';

class CheckCard extends StatelessWidget {
  final Check check;
  final VoidCallback onTap;
  final Function(bool)? onToggle;
  final bool showToggle;

  const CheckCard({
    super.key,
    required this.check,
    required this.onTap,
    this.onToggle,
    this.showToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      check.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: check.enabled ? null : AppTheme.textLight,
                      ),
                    ),
                    if (check.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        check.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: check.enabled 
                              ? AppTheme.textSecondary 
                              : AppTheme.textLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildMetadata(context),
                  ],
                ),
              ),
              if (showToggle && onToggle != null) ...[
                const SizedBox(width: 16),
                Switch(
                  value: check.enabled,
                  onChanged: onToggle,
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final categoryIcon = _getCategoryIcon(check.category);
    final color = check.enabled ? AppTheme.primaryColor : AppTheme.textLight;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        categoryIcon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Row(
      children: [
        _buildCategoryChip(),
        const SizedBox(width: 8),
        if (check.analytics != null) ...[
          _buildCompletionRate(context),
        ],
      ],
    );
  }

  Widget _buildCategoryChip() {
    final categoryName = _getCategoryDisplayName(check.category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        categoryName,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildCompletionRate(BuildContext context) {
    final analytics = check.analytics!;
    final completionRate = analytics.completionRate * 100;
    
    Color rateColor;
    if (completionRate >= 80) {
      rateColor = AppTheme.successColor;
    } else if (completionRate >= 60) {
      rateColor = AppTheme.warningColor;
    } else {
      rateColor = AppTheme.errorColor;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.analytics,
          size: 12,
          color: rateColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${completionRate.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: rateColor,
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(CheckCategory category) {
    switch (category) {
      case CheckCategory.hydration:
        return Icons.water_drop;
      case CheckCategory.posture:
        return Icons.accessibility_new;
      case CheckCategory.medication:
        return Icons.medication;
      case CheckCategory.screenBreak:
        return Icons.remove_red_eye;
      case CheckCategory.breathing:
        return Icons.air;
      case CheckCategory.exercise:
        return Icons.fitness_center;
      case CheckCategory.custom:
        return Icons.star;
    }
  }

  String _getCategoryDisplayName(CheckCategory category) {
    switch (category) {
      case CheckCategory.hydration:
        return 'Hydration';
      case CheckCategory.posture:
        return 'Posture';
      case CheckCategory.medication:
        return 'Medication';
      case CheckCategory.screenBreak:
        return 'Screen Break';
      case CheckCategory.breathing:
        return 'Breathing';
      case CheckCategory.exercise:
        return 'Exercise';
      case CheckCategory.custom:
        return 'Custom';
    }
  }
}
