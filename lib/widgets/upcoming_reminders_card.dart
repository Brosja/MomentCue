import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../services/time_service.dart';
import '../utils/app_theme.dart';

class UpcomingRemindersCard extends StatelessWidget {
  final List<ScheduleOccurrence> occurrences;
  final Function(ScheduleOccurrence)? onOccurrenceTap;

  const UpcomingRemindersCard({
    super.key,
    required this.occurrences,
    this.onOccurrenceTap,
  });

  @override
  Widget build(BuildContext context) {
    final pendingOccurrences = occurrences
        .where((o) => o.status == OccurrenceStatus.pending)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Reminders',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pendingOccurrences.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pendingOccurrences.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (pendingOccurrences.isEmpty)
              _buildEmptyState()
            else
              ...pendingOccurrences.map((occurrence) => _buildReminderItem(occurrence)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: AppTheme.successColor.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No more reminders for today',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(ScheduleOccurrence occurrence) {
    final timeService = TimeService.instance;
    final scheduledTime = occurrence.scheduledTime;
    final isOverdue = scheduledTime.isBefore(timeService.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onOccurrenceTap?.call(occurrence),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOverdue 
                ? AppTheme.errorColor.withOpacity(0.05)
                : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue 
                  ? AppTheme.errorColor.withOpacity(0.2)
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildTimeIndicator(scheduledTime, isOverdue),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCheckTitle(occurrence.checkId),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? AppTheme.errorColor : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRelativeTime(scheduledTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? AppTheme.errorColor : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusIndicator(occurrence, isOverdue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeIndicator(DateTime scheduledTime, bool isOverdue) {
    final timeString = TimeService.instance.formatLocal(scheduledTime, 'HH:mm');
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: isOverdue 
            ? AppTheme.errorColor.withOpacity(0.1)
            : AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 20,
            color: isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
          ),
          const SizedBox(height: 2),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ScheduleOccurrence occurrence, bool isOverdue) {
    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Overdue',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.errorColor,
          ),
        ),
      );
    }

    if (occurrence.isSnoozed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Snoozed',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.warningColor,
          ),
        ),
      );
    }

    return Icon(
      Icons.chevron_right,
      color: AppTheme.textLight,
      size: 20,
    );
  }

  String _getCheckTitle(String checkId) {
    // In a real implementation, you would look up the check by ID
    // For now, we'll return a placeholder
    return 'Health Check';
  }

  String _getRelativeTime(DateTime scheduledTime) {
    final timeService = TimeService.instance;
    final now = timeService.now();
    final difference = scheduledTime.difference(now);

    if (difference.isNegative) {
      // Overdue
      final absDifference = difference.abs();
      if (absDifference.inMinutes < 60) {
        return '${absDifference.inMinutes} min overdue';
      } else if (absDifference.inHours < 24) {
        return '${absDifference.inHours} hours overdue';
      } else {
        return '${absDifference.inDays} days overdue';
      }
    } else {
      // Upcoming
      if (difference.inMinutes < 60) {
        return 'In ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'In ${difference.inHours} hours';
      } else {
        return 'In ${difference.inDays} days';
      }
    }
  }
}
