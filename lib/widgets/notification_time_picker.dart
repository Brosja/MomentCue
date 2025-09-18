import 'package:flutter/material.dart';
import '../models/simple_check.dart';
import '../utils/app_theme.dart';

class NotificationTimePicker extends StatefulWidget {
  final List<NotificationTime> initialTimes;
  final Function(List<NotificationTime>) onChanged;

  const NotificationTimePicker({
    super.key,
    required this.initialTimes,
    required this.onChanged,
  });

  @override
  State<NotificationTimePicker> createState() => _NotificationTimePickerState();
}

class _NotificationTimePickerState extends State<NotificationTimePicker> {
  late List<NotificationTime> _notificationTimes;

  @override
  void initState() {
    super.initState();
    _notificationTimes = List.from(widget.initialTimes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Notification Times',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _addNotificationTime,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_notificationTimes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'No notification times set',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ..._notificationTimes.asMap().entries.map((entry) {
            final index = entry.key;
            final notificationTime = entry.value;
            return _buildNotificationTimeCard(index, notificationTime);
          }).toList(),
      ],
    );
  }

  Widget _buildNotificationTimeCard(int index, NotificationTime notificationTime) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificationTime.displayTime,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notificationTime.weekdayString,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _editNotificationTime(index),
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppTheme.primaryColor,
                ),
                IconButton(
                  onPressed: () => _removeNotificationTime(index),
                  icon: const Icon(Icons.delete, size: 20),
                  color: AppTheme.errorColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNotificationTime() {
    _showTimePickerDialog();
  }

  void _editNotificationTime(int index) {
    _showTimePickerDialog(initialTime: _notificationTimes[index], index: index);
  }

  void _removeNotificationTime(int index) {
    setState(() {
      _notificationTimes.removeAt(index);
    });
    widget.onChanged(_notificationTimes);
  }

  void _showTimePickerDialog({NotificationTime? initialTime, int? index}) {
    TimeOfDay selectedTime = TimeOfDay.now();
    List<int> selectedWeekdays = [];
    bool isEnabled = true;

    if (initialTime != null) {
      selectedTime = TimeOfDay(hour: initialTime.hour, minute: initialTime.minute);
      selectedWeekdays = List.from(initialTime.weekdays);
      isEnabled = initialTime.isEnabled;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(initialTime != null ? 'Edit Notification' : 'Add Notification'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time Picker
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = time;
                      });
                    }
                  },
                ),
                const Divider(),
                // Weekday Selection
                const Text(
                  'Days of the week',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (dayIndex) {
                    final dayNumber = dayIndex + 1;
                    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final isSelected = selectedWeekdays.contains(dayNumber);
                    
                    return FilterChip(
                      label: Text(dayNames[dayIndex]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedWeekdays.add(dayNumber);
                          } else {
                            selectedWeekdays.remove(dayNumber);
                          }
                        });
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Enable/Disable
                SwitchListTile(
                  title: const Text('Enable notification'),
                  value: isEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      isEnabled = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final notificationTime = NotificationTime(
                  hour: selectedTime.hour,
                  minute: selectedTime.minute,
                  weekdays: selectedWeekdays,
                  isEnabled: isEnabled,
                );

                setState(() {
                  if (index != null) {
                    _notificationTimes[index] = notificationTime;
                  } else {
                    _notificationTimes.add(notificationTime);
                  }
                });
                widget.onChanged(_notificationTimes);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(initialTime != null ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
