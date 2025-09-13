import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

class HeatmapCalendar extends StatelessWidget {
  final Map<String, int> data;
  final int? maxValue;

  const HeatmapCalendar({
    super.key,
    required this.data,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final max = maxValue ?? _getMaxValue();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegend(max),
        const SizedBox(height: 16),
        _buildCalendar(thirtyDaysAgo, max),
        const SizedBox(height: 8),
        _buildMonthLabels(thirtyDaysAgo),
      ],
    );
  }

  Widget _buildLegend(int max) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Less',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            final intensity = index / 4.0;
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: _getIntensityColor(intensity),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const Text(
          'More',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(DateTime startDate, int max) {
    final weeks = <Widget>[];
    final currentDate = startDate;
    
    // Create 5 weeks of data (35 days)
    for (int week = 0; week < 5; week++) {
      final weekDays = <Widget>[];
      
      for (int day = 0; day < 7; day++) {
        final date = currentDate.add(Duration(days: week * 7 + day));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final value = data[dateStr] ?? 0;
        final intensity = max > 0 ? value / max : 0.0;
        
        weekDays.add(
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: _getIntensityColor(intensity),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 0.5,
              ),
            ),
            child: Tooltip(
              message: '${date.day}/${date.month}: $value checks',
              child: Container(),
            ),
          ),
        );
      }
      
      weeks.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays,
        ),
      );
    }
    
    return Column(children: weeks);
  }

  Widget _buildMonthLabels(DateTime startDate) {
    final months = <String>[];
    final currentDate = startDate;
    
    for (int i = 0; i < 5; i++) {
      final date = currentDate.add(Duration(days: i * 7));
      final monthName = _getMonthName(date.month);
      if (i == 0 || date.day <= 7) {
        months.add(monthName);
      } else {
        months.add('');
      }
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: months.map((month) => Text(
        month,
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.textSecondary,
        ),
      )).toList(),
    );
  }

  Color _getIntensityColor(double intensity) {
    if (intensity == 0) {
      return Colors.grey.shade100;
    } else if (intensity <= 0.25) {
      return AppTheme.primaryColor.withOpacity(0.3);
    } else if (intensity <= 0.5) {
      return AppTheme.primaryColor.withOpacity(0.5);
    } else if (intensity <= 0.75) {
      return AppTheme.primaryColor.withOpacity(0.7);
    } else {
      return AppTheme.primaryColor;
    }
  }

  int _getMaxValue() {
    if (data.isEmpty) return 1;
    return data.values.reduce((a, b) => a > b ? a : b);
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
