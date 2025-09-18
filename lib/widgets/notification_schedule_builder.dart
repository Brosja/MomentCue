import 'package:flutter/material.dart';
import '../models/notification_schedule.dart';
import '../utils/app_theme.dart';

class NotificationScheduleBuilder extends StatefulWidget {
  final NotificationSchedule? initialSchedule;
  final Function(NotificationSchedule) onChanged;

  const NotificationScheduleBuilder({
    super.key,
    this.initialSchedule,
    required this.onChanged,
  });

  @override
  State<NotificationScheduleBuilder> createState() => _NotificationScheduleBuilderState();
}

class _NotificationScheduleBuilderState extends State<NotificationScheduleBuilder> {
  late ScheduleType _selectedType;
  late Map<String, dynamic> _scheduleData;
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialSchedule != null) {
      _selectedType = widget.initialSchedule!.scheduleType;
      _scheduleData = Map.from(widget.initialSchedule!.scheduleData);
      _isEnabled = widget.initialSchedule!.isEnabled;
    } else {
      _selectedType = ScheduleType.daily;
      _scheduleData = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildScheduleTypeSelector(),
            const SizedBox(height: 16),
            _buildScheduleConfiguration(),
            const SizedBox(height: 16),
            _buildPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.schedule, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Notification Schedule',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Switch(
          value: _isEnabled,
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
            });
            _notifyChanged();
          },
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildScheduleTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ScheduleType.values.map((type) {
            return FilterChip(
              label: Text(_getScheduleTypeLabel(type)),
              selected: _selectedType == type,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                    _scheduleData = _getDefaultDataForType(type);
                  });
                  _notifyChanged();
                }
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleConfiguration() {
    switch (_selectedType) {
      case ScheduleType.interval:
        return _buildIntervalConfiguration();
      case ScheduleType.daily:
        return _buildDailyConfiguration();
      case ScheduleType.weekly:
        return _buildWeeklyConfiguration();
      case ScheduleType.monthly:
        return _buildMonthlyConfiguration();
      case ScheduleType.yearly:
        return _buildYearlyConfiguration();
      case ScheduleType.weekday:
        return _buildWeekdayConfiguration();
      case ScheduleType.weekend:
        return _buildWeekendConfiguration();
      case ScheduleType.custom:
        return _buildCustomConfiguration();
    }
  }

  Widget _buildIntervalConfiguration() {
    final interval = _scheduleData['interval'] as int? ?? 1;
    final unit = TimeUnit.values[_scheduleData['unit'] as int? ?? 0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat Every',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: interval.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Interval',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final newInterval = int.tryParse(value) ?? 1;
                  setState(() {
                    _scheduleData['interval'] = newInterval;
                  });
                  _notifyChanged();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<TimeUnit>(
                value: unit,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: TimeUnit.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(_getUnitName(unit)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _scheduleData['unit'] = value.index;
                    });
                    _notifyChanged();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyConfiguration() {
    final times = (_scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Times',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
            ),
          ],
        ),
        if (times.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'No times set',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...times.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return _buildTimeCard(index, time, () => _removeTime(index));
          }).toList(),
      ],
    );
  }

  Widget _buildWeeklyConfiguration() {
    final days = (_scheduleData['days'] as List<dynamic>?)?.cast<int>() ?? [];
    final times = (_scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days of Week',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final dayNumber = index + 1;
            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final isSelected = days.contains(dayNumber);
            
            return FilterChip(
              label: Text(dayNames[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    days.add(dayNumber);
                  } else {
                    days.remove(dayNumber);
                  }
                  _scheduleData['days'] = days;
                });
                _notifyChanged();
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            );
          }),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Times',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
            ),
          ],
        ),
        if (times.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'No times set',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...times.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return _buildTimeCard(index, time, () => _removeTime(index));
          }).toList(),
      ],
    );
  }

  Widget _buildMonthlyConfiguration() {
    final dayOfMonth = _scheduleData['dayOfMonth'] as int?;
    final weekOfMonth = _scheduleData['weekOfMonth'] as int?;
    final dayOfWeek = _scheduleData['dayOfWeek'] as int?;
    final times = (_scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Pattern',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<int>(
                title: const Text('Day of Month'),
                value: 1,
                groupValue: dayOfMonth != null ? 1 : (weekOfMonth != null ? 2 : 1),
                onChanged: (value) {
                  setState(() {
                    _scheduleData['dayOfMonth'] = 1;
                    _scheduleData['weekOfMonth'] = null;
                    _scheduleData['dayOfWeek'] = null;
                  });
                  _notifyChanged();
                },
              ),
            ),
            Expanded(
              child: RadioListTile<int>(
                title: const Text('Week of Month'),
                value: 2,
                groupValue: weekOfMonth != null ? 2 : (dayOfMonth != null ? 1 : 1),
                onChanged: (value) {
                  setState(() {
                    _scheduleData['dayOfMonth'] = null;
                    _scheduleData['weekOfMonth'] = 1;
                    _scheduleData['dayOfWeek'] = 1;
                  });
                  _notifyChanged();
                },
              ),
            ),
          ],
        ),
        if (dayOfMonth != null) ...[
          const SizedBox(height: 8),
          TextFormField(
            initialValue: dayOfMonth.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Day of Month (1-31)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final day = int.tryParse(value) ?? 1;
              setState(() {
                _scheduleData['dayOfMonth'] = day.clamp(1, 31);
              });
              _notifyChanged();
            },
          ),
        ],
        if (weekOfMonth != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: weekOfMonth,
                  decoration: const InputDecoration(
                    labelText: 'Week',
                    border: OutlineInputBorder(),
                  ),
                  items: [1, 2, 3, 4, 5].map((week) {
                    return DropdownMenuItem(
                      value: week,
                      child: Text('Week $week'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _scheduleData['weekOfMonth'] = value;
                      });
                      _notifyChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: dayOfWeek ?? 1,
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(7, (index) {
                    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(dayNames[index]),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _scheduleData['dayOfWeek'] = value;
                      });
                      _notifyChanged();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Times',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
            ),
          ],
        ),
        if (times.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'No times set',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...times.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return _buildTimeCard(index, time, () => _removeTime(index));
          }).toList(),
      ],
    );
  }

  Widget _buildYearlyConfiguration() {
    final month = _scheduleData['month'] as int? ?? 1;
    final dayOfMonth = _scheduleData['dayOfMonth'] as int? ?? 1;
    final times = (_scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: month,
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (index) {
                  final monthNames = [
                    'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                  ];
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(monthNames[index]),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _scheduleData['month'] = value;
                    });
                    _notifyChanged();
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: dayOfMonth.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Day (1-31)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final day = int.tryParse(value) ?? 1;
                  setState(() {
                    _scheduleData['dayOfMonth'] = day.clamp(1, 31);
                  });
                  _notifyChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Times',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
            ),
          ],
        ),
        if (times.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'No times set',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...times.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return _buildTimeCard(index, time, () => _removeTime(index));
          }).toList(),
      ],
    );
  }

  Widget _buildWeekdayConfiguration() {
    final times = (_scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekdays (Monday - Friday)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Times',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
            ),
          ],
        ),
        if (times.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'No times set',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...times.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return _buildTimeCard(index, time, () => _removeTime(index));
          }).toList(),
      ],
    );
  }

  Widget _buildWeekendConfiguration() {
    final times = (_scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekends (Saturday - Sunday)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Times',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Time'),
            ),
          ],
        ),
        if (times.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text(
                'No times set',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...times.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return _buildTimeCard(index, time, () => _removeTime(index));
          }).toList(),
      ],
    );
  }

  Widget _buildCustomConfiguration() {
    final description = _scheduleData['description'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Schedule Description',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: description,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'e.g., Every 2nd Tuesday of the month',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (value) {
            setState(() {
              _scheduleData['description'] = value;
            });
            _notifyChanged();
          },
        ),
      ],
    );
  }

  Widget _buildTimeCard(int index, Map<String, dynamic> time, VoidCallback onRemove) {
    final hour = time['hour'] as int;
    final minute = time['minute'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatTime(hour, minute),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              onPressed: () => _editTime(index),
              icon: const Icon(Icons.edit, size: 20),
              color: AppTheme.primaryColor,
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete, size: 20),
              color: AppTheme.errorColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final schedule = NotificationSchedule(
      id: widget.initialSchedule?.id ?? '',
      checkId: widget.initialSchedule?.checkId ?? '',
      title: widget.initialSchedule?.title ?? '',
      description: widget.initialSchedule?.description,
      isEnabled: _isEnabled,
      scheduleType: _selectedType,
      scheduleData: _scheduleData,
      createdAt: widget.initialSchedule?.createdAt ?? DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            schedule.displayText,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getScheduleTypeLabel(ScheduleType type) {
    switch (type) {
      case ScheduleType.interval:
        return 'Interval';
      case ScheduleType.daily:
        return 'Daily';
      case ScheduleType.weekly:
        return 'Weekly';
      case ScheduleType.monthly:
        return 'Monthly';
      case ScheduleType.yearly:
        return 'Yearly';
      case ScheduleType.weekday:
        return 'Weekdays';
      case ScheduleType.weekend:
        return 'Weekends';
      case ScheduleType.custom:
        return 'Custom';
    }
  }

  String _getUnitName(TimeUnit unit) {
    switch (unit) {
      case TimeUnit.minutes:
        return 'Minutes';
      case TimeUnit.hours:
        return 'Hours';
      case TimeUnit.days:
        return 'Days';
      case TimeUnit.weeks:
        return 'Weeks';
      case TimeUnit.months:
        return 'Months';
      case TimeUnit.years:
        return 'Years';
    }
  }

  Map<String, dynamic> _getDefaultDataForType(ScheduleType type) {
    switch (type) {
      case ScheduleType.interval:
        return {'interval': 1, 'unit': TimeUnit.hours.index};
      case ScheduleType.daily:
      case ScheduleType.weekday:
      case ScheduleType.weekend:
        return {'times': []};
      case ScheduleType.weekly:
        return {'days': [], 'times': []};
      case ScheduleType.monthly:
        return {'dayOfMonth': 1, 'times': []};
      case ScheduleType.yearly:
        return {'month': 1, 'dayOfMonth': 1, 'times': []};
      case ScheduleType.custom:
        return {'description': ''};
    }
  }

  void _addTime() {
    _showTimePicker();
  }

  void _editTime(int index) {
    _showTimePicker(initialTime: _scheduleData['times'][index], index: index);
  }

  void _removeTime(int index) {
    setState(() {
      final times = List<Map<String, dynamic>>.from(_scheduleData['times'] ?? []);
      times.removeAt(index);
      _scheduleData['times'] = times;
    });
    _notifyChanged();
  }

  void _showTimePicker({Map<String, dynamic>? initialTime, int? index}) {
    TimeOfDay selectedTime = TimeOfDay.now();
    
    if (initialTime != null) {
      selectedTime = TimeOfDay(hour: initialTime['hour'], minute: initialTime['minute']);
    }

    showTimePicker(
      context: context,
      initialTime: selectedTime,
    ).then((time) {
      if (time != null) {
        setState(() {
          final times = List<Map<String, dynamic>>.from(_scheduleData['times'] ?? []);
          final newTime = {'hour': time.hour, 'minute': time.minute};
          
          if (index != null) {
            times[index] = newTime;
          } else {
            times.add(newTime);
          }
          
          _scheduleData['times'] = times;
        });
        _notifyChanged();
      }
    });
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  void _notifyChanged() {
    final schedule = NotificationSchedule(
      id: widget.initialSchedule?.id ?? '',
      checkId: widget.initialSchedule?.checkId ?? '',
      title: widget.initialSchedule?.title ?? '',
      description: widget.initialSchedule?.description,
      isEnabled: _isEnabled,
      scheduleType: _selectedType,
      scheduleData: _scheduleData,
      createdAt: widget.initialSchedule?.createdAt ?? DateTime.now(),
    );
    
    widget.onChanged(schedule);
  }
}
