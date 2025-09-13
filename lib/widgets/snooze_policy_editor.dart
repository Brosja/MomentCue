import 'package:flutter/material.dart';

import '../models/check.dart';
import '../utils/app_theme.dart';

class SnoozePolicyEditor extends StatelessWidget {
  final SnoozePolicy snoozePolicy;
  final Function(SnoozePolicy) onChanged;

  const SnoozePolicyEditor({
    super.key,
    required this.snoozePolicy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Allow Snoozing'),
          subtitle: const Text('Enable snooze options in notifications'),
          value: snoozePolicy.allowSnooze,
          onChanged: (value) {
            final updatedPolicy = SnoozePolicy(
              allowSnooze: value,
              maxSnoozes: snoozePolicy.maxSnoozes,
              snoozeOptions: snoozePolicy.snoozeOptions,
              defaultSnooze: snoozePolicy.defaultSnooze,
            );
            onChanged(updatedPolicy);
          },
          activeColor: AppTheme.primaryColor,
          contentPadding: EdgeInsets.zero,
        ),
        
        if (snoozePolicy.allowSnooze) ...[
          const SizedBox(height: 16),
          
          // Max snoozes
          Row(
            children: [
              Expanded(
                child: Text(
                  'Maximum snoozes per reminder',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              DropdownButton<int>(
                value: snoozePolicy.maxSnoozes,
                items: [1, 2, 3, 4, 5].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final updatedPolicy = SnoozePolicy(
                      allowSnooze: snoozePolicy.allowSnooze,
                      maxSnoozes: value,
                      snoozeOptions: snoozePolicy.snoozeOptions,
                      defaultSnooze: snoozePolicy.defaultSnooze,
                    );
                    onChanged(updatedPolicy);
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Default snooze duration
          Row(
            children: [
              Expanded(
                child: Text(
                  'Default snooze duration',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              DropdownButton<int>(
                value: snoozePolicy.defaultSnooze,
                items: snoozePolicy.snoozeOptions.map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text(_formatDuration(minutes)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final updatedPolicy = SnoozePolicy(
                      allowSnooze: snoozePolicy.allowSnooze,
                      maxSnoozes: snoozePolicy.maxSnoozes,
                      snoozeOptions: snoozePolicy.snoozeOptions,
                      defaultSnooze: value,
                    );
                    onChanged(updatedPolicy);
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Snooze options
          Text(
            'Available snooze options',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildSnoozeOptionChips(),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildSnoozeOptionChips() {
    final availableOptions = [5, 10, 15, 30, 45, 60, 90, 120];
    
    return availableOptions.map((minutes) {
      final isSelected = snoozePolicy.snoozeOptions.contains(minutes);
      
      return FilterChip(
        label: Text(_formatDuration(minutes)),
        selected: isSelected,
        onSelected: (selected) {
          List<int> newOptions = List.from(snoozePolicy.snoozeOptions);
          
          if (selected) {
            newOptions.add(minutes);
          } else {
            newOptions.remove(minutes);
          }
          
          // Ensure we have at least one option
          if (newOptions.isEmpty) {
            newOptions = [10];
          }
          
          // Sort the options
          newOptions.sort();
          
          // Make sure the default snooze is still available
          int defaultSnooze = snoozePolicy.defaultSnooze;
          if (!newOptions.contains(defaultSnooze)) {
            defaultSnooze = newOptions.first;
          }
          
          final updatedPolicy = SnoozePolicy(
            allowSnooze: snoozePolicy.allowSnooze,
            maxSnoozes: snoozePolicy.maxSnoozes,
            snoozeOptions: newOptions,
            defaultSnooze: defaultSnooze,
          );
          onChanged(updatedPolicy);
        },
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
      );
    }).toList();
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }
}
