import 'package:flutter/material.dart';

import '../models/check.dart';
import '../models/schedule.dart';
import '../utils/app_theme.dart';

class SchedulePicker extends StatefulWidget {
  final ScheduleType scheduleType;
  final Map<String, dynamic> scheduleData;
  final String? rruleString;
  final Function(ScheduleType, Map<String, dynamic>, String?) onScheduleChanged;

  const SchedulePicker({
    super.key,
    required this.scheduleType,
    required this.scheduleData,
    this.rruleString,
    required this.onScheduleChanged,
  });

  @override
  State<SchedulePicker> createState() => _SchedulePickerState();
}

class _SchedulePickerState extends State<SchedulePicker> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScheduleType _currentScheduleType;
  late Map<String, dynamic> _currentScheduleData;
  String? _currentRruleString;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentScheduleType = widget.scheduleType;
    _currentScheduleData = Map.from(widget.scheduleData);
    _currentRruleString = widget.rruleString;
    
    // Set initial tab based on schedule type
    if (_currentScheduleType == ScheduleType.rrule) {
      _tabController.index = 1;
    } else if (_currentScheduleType == ScheduleType.sequence) {
      _tabController.index = 2;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateSchedule(ScheduleType type, Map<String, dynamic> data, [String? rrule]) {
    setState(() {
      _currentScheduleType = type;
      _currentScheduleData = data;
      _currentRruleString = rrule;
    });
    widget.onScheduleChanged(type, data, rrule);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Simple'),
            Tab(text: 'Advanced'),
            Tab(text: 'Sequence'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSimpleSchedule(),
              _buildAdvancedSchedule(),
              _buildSequenceSchedule(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleSchedule() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildScheduleTypeSelector(),
          const SizedBox(height: 16),
          _buildScheduleConfiguration(),
        ],
      ),
    );
  }

  Widget _buildScheduleTypeSelector() {
    final simpleTypes = [
      ScheduleType.oneTime,
      ScheduleType.daily,
      ScheduleType.weekdays,
      ScheduleType.weekly,
      ScheduleType.monthly,
      ScheduleType.yearly,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Type',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: simpleTypes.map((type) {
            final isSelected = _currentScheduleType == type;
            
            return ChoiceChip(
              label: Text(_getScheduleTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _setDefaultDataForType(type);
                }
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleConfiguration() {
    switch (_currentScheduleType) {
      case ScheduleType.oneTime:
        return _buildOneTimeConfig();
      case ScheduleType.daily:
        return _buildDailyConfig();
      case ScheduleType.weekdays:
        return _buildWeekdaysConfig();
      case ScheduleType.weekly:
        return _buildWeeklyConfig();
      case ScheduleType.monthly:
        return _buildMonthlyConfig();
      case ScheduleType.yearly:
        return _buildYearlyConfig();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOneTimeConfig() {
    final DateTime selectedDate = _currentScheduleData['dateTime'] != null
        ? DateTime.parse(_currentScheduleData['dateTime'])
        : DateTime.now().add(const Duration(hours: 1));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDateTime(selectedDate),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule),
                    const SizedBox(width: 12),
                    Text(
                      _formatDateTime(selectedDate),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyConfig() {
    final time = _currentScheduleData['time'] ?? {'hour': 9, 'minute': 0};
    final interval = _currentScheduleData['interval'] ?? 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSelector(time),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Repeat every',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                DropdownButton<int>(
                  value: interval,
                  items: [1, 2, 3, 4, 5, 6, 7].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text('$value ${value == 1 ? 'day' : 'days'}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateSchedule(
                        _currentScheduleType,
                        {..._currentScheduleData, 'interval': value},
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaysConfig() {
    final time = _currentScheduleData['time'] ?? {'hour': 9, 'minute': 0};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSelector(time),
            const SizedBox(height: 16),
            Text(
              'Monday through Friday',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyConfig() {
    final time = _currentScheduleData['time'] ?? {'hour': 9, 'minute': 0};
    final weekdays = _currentScheduleData['weekdays'] ?? [1]; // Default to Monday

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSelector(time),
            const SizedBox(height: 16),
            Text(
              'Days of the week',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildWeekdaySelector(weekdays),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyConfig() {
    final time = _currentScheduleData['time'] ?? {'hour': 9, 'minute': 0};
    final dayOfMonth = _currentScheduleData['dayOfMonth'];
    final monthlyType = dayOfMonth != null ? 'date' : 'weekday';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSelector(time),
            const SizedBox(height: 16),
            Text(
              'Monthly recurrence',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('On a specific date'),
              subtitle: Text('e.g., 15th of each month'),
              value: 'date',
              groupValue: monthlyType,
              onChanged: (value) {
                _updateSchedule(
                  _currentScheduleType,
                  {
                    ..._currentScheduleData,
                    'dayOfMonth': 1,
                    'weekOfMonth': null,
                    'dayOfWeek': null,
                  },
                );
              },
            ),
            if (monthlyType == 'date')
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: DropdownButton<int>(
                  value: dayOfMonth ?? 1,
                  items: List.generate(31, (index) => index + 1).map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text('${day}${_getOrdinalSuffix(day)}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateSchedule(
                        _currentScheduleType,
                        {..._currentScheduleData, 'dayOfMonth': value},
                      );
                    }
                  },
                ),
              ),
            RadioListTile<String>(
              title: const Text('On a specific weekday'),
              subtitle: const Text('e.g., first Monday of each month'),
              value: 'weekday',
              groupValue: monthlyType,
              onChanged: (value) {
                _updateSchedule(
                  _currentScheduleType,
                  {
                    ..._currentScheduleData,
                    'dayOfMonth': null,
                    'weekOfMonth': 1,
                    'dayOfWeek': 1,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyConfig() {
    final time = _currentScheduleData['time'] ?? {'hour': 9, 'minute': 0};
    final month = _currentScheduleData['month'] ?? 1;
    final day = _currentScheduleData['day'] ?? 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeSelector(time),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: month,
                    isExpanded: true,
                    items: List.generate(12, (index) => index + 1).map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(_getMonthName(month)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateSchedule(
                          _currentScheduleType,
                          {..._currentScheduleData, 'month': value},
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: day,
                    isExpanded: true,
                    items: List.generate(31, (index) => index + 1).map((day) {
                      return DropdownMenuItem(
                        value: day,
                        child: Text('${day}${_getOrdinalSuffix(day)}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateSchedule(
                          _currentScheduleType,
                          {..._currentScheduleData, 'day': value},
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(Map<String, dynamic> time) {
    return Row(
      children: [
        const Icon(Icons.schedule),
        const SizedBox(width: 12),
        Text(
          'Time:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: () => _selectTime(time),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${time['hour'].toString().padLeft(2, '0')}:${time['minute'].toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdaySelector(List<int> selectedWeekdays) {
    final weekdays = [
      {'value': 1, 'label': 'Mon'},
      {'value': 2, 'label': 'Tue'},
      {'value': 3, 'label': 'Wed'},
      {'value': 4, 'label': 'Thu'},
      {'value': 5, 'label': 'Fri'},
      {'value': 6, 'label': 'Sat'},
      {'value': 7, 'label': 'Sun'},
    ];

    return Wrap(
      spacing: 8,
      children: weekdays.map((weekday) {
        final isSelected = selectedWeekdays.contains(weekday['value']);
        
        return FilterChip(
          label: Text(weekday['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            List<int> newWeekdays = List.from(selectedWeekdays);
            
            if (selected) {
              newWeekdays.add(weekday['value'] as int);
            } else {
              newWeekdays.remove(weekday['value']);
            }
            
            // Ensure at least one weekday is selected
            if (newWeekdays.isEmpty) {
              newWeekdays = [1];
            }
            
            newWeekdays.sort();
            
            _updateSchedule(
              _currentScheduleType,
              {..._currentScheduleData, 'weekdays': newWeekdays},
            );
          },
          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
          checkmarkColor: AppTheme.primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedSchedule() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RRULE (RFC5545)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a custom recurrence rule for advanced scheduling.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _currentRruleString ?? '',
            decoration: const InputDecoration(
              labelText: 'RRULE String',
              hintText: 'FREQ=DAILY;INTERVAL=1',
              helperText: 'Example: FREQ=WEEKLY;BYDAY=MO,WE,FR',
            ),
            maxLines: 2,
            onChanged: (value) {
              _updateSchedule(ScheduleType.rrule, {}, value.isEmpty ? null : value);
            },
          ),
          const SizedBox(height: 16),
          _buildRRuleExamples(),
        ],
      ),
    );
  }

  Widget _buildRRuleExamples() {
    final examples = [
      {'label': 'Every day', 'rrule': 'FREQ=DAILY'},
      {'label': 'Every weekday', 'rrule': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR'},
      {'label': 'Every 2 weeks', 'rrule': 'FREQ=WEEKLY;INTERVAL=2'},
      {'label': 'First Monday of month', 'rrule': 'FREQ=MONTHLY;BYDAY=1MO'},
      {'label': 'Every 6 months', 'rrule': 'FREQ=MONTHLY;INTERVAL=6'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Examples',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...examples.map((example) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              _updateSchedule(ScheduleType.rrule, {}, example['rrule']);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    example['label'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    example['rrule'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildSequenceSchedule() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Sequence Scheduling',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Custom interval sequences coming soon! Create reminders with varying intervals like: +2 days, +1 week, +3 days...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScheduleTypeLabel(ScheduleType type) {
    switch (type) {
      case ScheduleType.oneTime:
        return 'One Time';
      case ScheduleType.daily:
        return 'Daily';
      case ScheduleType.weekdays:
        return 'Weekdays';
      case ScheduleType.weekly:
        return 'Weekly';
      case ScheduleType.monthly:
        return 'Monthly';
      case ScheduleType.yearly:
        return 'Yearly';
      case ScheduleType.rrule:
        return 'Custom';
      case ScheduleType.sequence:
        return 'Sequence';
    }
  }

  void _setDefaultDataForType(ScheduleType type) {
    Map<String, dynamic> defaultData = {};
    
    switch (type) {
      case ScheduleType.oneTime:
        defaultData = {
          'dateTime': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        };
        break;
      case ScheduleType.daily:
        defaultData = {
          'type': 'daily',
          'time': {'hour': 9, 'minute': 0},
          'interval': 1,
        };
        break;
      case ScheduleType.weekdays:
        defaultData = {
          'type': 'weekdays',
          'time': {'hour': 9, 'minute': 0},
        };
        break;
      case ScheduleType.weekly:
        defaultData = {
          'type': 'weekly',
          'time': {'hour': 9, 'minute': 0},
          'weekdays': [1], // Monday
        };
        break;
      case ScheduleType.monthly:
        defaultData = {
          'type': 'monthly',
          'time': {'hour': 9, 'minute': 0},
          'dayOfMonth': 1,
        };
        break;
      case ScheduleType.yearly:
        defaultData = {
          'type': 'yearly',
          'time': {'hour': 9, 'minute': 0},
          'month': 1,
          'day': 1,
        };
        break;
      default:
        defaultData = {};
    }
    
    _updateSchedule(type, defaultData);
  }

  Future<void> _selectDateTime(DateTime currentDateTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDateTime),
      );
      
      if (time != null && mounted) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        _updateSchedule(
          _currentScheduleType,
          {'dateTime': newDateTime.toIso8601String()},
        );
      }
    }
  }

  Future<void> _selectTime(Map<String, dynamic> currentTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentTime['hour'] ?? 9,
        minute: currentTime['minute'] ?? 0,
      ),
    );
    
    if (time != null && mounted) {
      _updateSchedule(
        _currentScheduleType,
        {
          ..._currentScheduleData,
          'time': {'hour': time.hour, 'minute': time.minute},
        },
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}
