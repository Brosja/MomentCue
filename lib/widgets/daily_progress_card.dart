import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../utils/app_theme.dart';

class DailyProgressCard extends StatelessWidget {
  final List<ScheduleOccurrence> occurrences;
  final VoidCallback? onTap;

  const DailyProgressCard({
    super.key,
    required this.occurrences,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = occurrences.where((o) => o.isCompleted).length;
    final totalCount = occurrences.length;
    final progressPercentage = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedCount of $totalCount',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'checks completed',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildCircularProgress(progressPercentage),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressBar(progressPercentage),
              const SizedBox(height: 12),
              _buildEncouragementText(progressPercentage, completedCount, totalCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularProgress(double progress) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
          ),
          Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getProgressColor(progress),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEncouragementText(double progress, int completed, int total) {
    String message;
    IconData icon;
    Color color;

    if (total == 0) {
      message = 'No reminders scheduled for today';
      icon = Icons.schedule;
      color = AppTheme.textSecondary;
    } else if (progress == 1.0) {
      message = 'Amazing! You completed all your checks today! 🎉';
      icon = Icons.celebration;
      color = AppTheme.successColor;
    } else if (progress >= 0.8) {
      message = 'Great job! You\'re almost there! Keep it up! 💪';
      icon = Icons.trending_up;
      color = AppTheme.successColor;
    } else if (progress >= 0.5) {
      message = 'Good progress! You\'re halfway there! 👍';
      icon = Icons.thumb_up;
      color = AppTheme.primaryColor;
    } else if (completed > 0) {
      message = 'Nice start! Every step counts! ✨';
      icon = Icons.star;
      color = AppTheme.warningColor;
    } else {
      message = 'Ready to start your wellness journey today?';
      icon = Icons.rocket_launch;
      color = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) {
      return AppTheme.successColor;
    } else if (progress >= 0.5) {
      return AppTheme.primaryColor;
    } else if (progress > 0) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.textLight;
    }
  }
}
