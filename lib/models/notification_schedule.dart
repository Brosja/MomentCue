import 'dart:convert';

enum TimeUnit {
  minutes,
  hours,
  days,
  weeks,
  months,
  years,
}

enum DayOfWeek {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  const DayOfWeek(this.value);
  final int value;

  static DayOfWeek fromValue(int value) {
    return DayOfWeek.values.firstWhere((day) => day.value == value);
  }
}

enum WeekOfMonth {
  first(1),
  second(2),
  third(3),
  fourth(4),
  last(-1);

  const WeekOfMonth(this.value);
  final int value;
}

enum MonthOfYear {
  january(1),
  february(2),
  march(3),
  april(4),
  may(5),
  june(6),
  july(7),
  august(8),
  september(9),
  october(10),
  november(11),
  december(12);

  const MonthOfYear(this.value);
  final int value;

  static MonthOfYear fromValue(int value) {
    return MonthOfYear.values.firstWhere((month) => month.value == value);
  }
}

class NotificationSchedule {
  final String id;
  final String checkId;
  final String title;
  final String? description;
  final bool isEnabled;
  final ScheduleType scheduleType;
  final Map<String, dynamic> scheduleData;
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final int triggerCount;

  const NotificationSchedule({
    required this.id,
    required this.checkId,
    required this.title,
    this.description,
    this.isEnabled = true,
    required this.scheduleType,
    required this.scheduleData,
    required this.createdAt,
    this.lastTriggered,
    this.triggerCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checkId': checkId,
      'title': title,
      'description': description,
      'isEnabled': isEnabled,
      'scheduleType': scheduleType.name,
      'scheduleData': scheduleData,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
      'triggerCount': triggerCount,
    };
  }

  factory NotificationSchedule.fromJson(Map<String, dynamic> json) {
    return NotificationSchedule(
      id: json['id'],
      checkId: json['checkId'],
      title: json['title'],
      description: json['description'],
      isEnabled: json['isEnabled'] ?? true,
      scheduleType: ScheduleType.values.firstWhere(
        (type) => type.name == json['scheduleType'],
        orElse: () => ScheduleType.interval,
      ),
      scheduleData: Map<String, dynamic>.from(json['scheduleData'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      lastTriggered: json['lastTriggered'] != null 
          ? DateTime.parse(json['lastTriggered']) 
          : null,
      triggerCount: json['triggerCount'] ?? 0,
    );
  }

  String get displayText {
    switch (scheduleType) {
      case ScheduleType.interval:
        return _getIntervalDisplay();
      case ScheduleType.daily:
        return _getDailyDisplay();
      case ScheduleType.weekly:
        return _getWeeklyDisplay();
      case ScheduleType.monthly:
        return _getMonthlyDisplay();
      case ScheduleType.yearly:
        return _getYearlyDisplay();
      case ScheduleType.weekday:
        return _getWeekdayDisplay();
      case ScheduleType.weekend:
        return _getWeekendDisplay();
      case ScheduleType.custom:
        return _getCustomDisplay();
    }
  }

  String _getIntervalDisplay() {
    final interval = scheduleData['interval'] as int? ?? 1;
    final unit = TimeUnit.values[scheduleData['unit'] as int? ?? 0];
    final unitName = _getUnitName(unit, interval);
    return 'Every $interval $unitName';
  }

  String _getDailyDisplay() {
    final times = (scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (times.isEmpty) return 'Daily (no times set)';
    
    final timeStrings = times.map((time) {
      final hour = time['hour'] as int;
      final minute = time['minute'] as int;
      return _formatTime(hour, minute);
    }).toList();
    
    return 'Daily at ${timeStrings.join(', ')}';
  }

  String _getWeeklyDisplay() {
    final days = (scheduleData['days'] as List<dynamic>?)?.cast<int>() ?? [];
    final times = (scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    if (days.isEmpty) return 'Weekly (no days set)';
    if (times.isEmpty) return 'Weekly (no times set)';
    
    final dayNames = days.map((day) => DayOfWeek.fromValue(day).name.capitalize()).join(', ');
    final timeStrings = times.map((time) {
      final hour = time['hour'] as int;
      final minute = time['minute'] as int;
      return _formatTime(hour, minute);
    }).toList();
    
    return 'Weekly on $dayNames at ${timeStrings.join(', ')}';
  }

  String _getMonthlyDisplay() {
    final dayOfMonth = scheduleData['dayOfMonth'] as int?;
    final weekOfMonth = scheduleData['weekOfMonth'] as int?;
    final dayOfWeek = scheduleData['dayOfWeek'] as int?;
    final times = (scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    if (times.isEmpty) return 'Monthly (no times set)';
    
    String dayText;
    if (dayOfMonth != null) {
      dayText = 'day $dayOfMonth';
    } else if (weekOfMonth != null && dayOfWeek != null) {
      final weekName = WeekOfMonth.values.firstWhere((w) => w.value == weekOfMonth).name.capitalize();
      final dayName = DayOfWeek.fromValue(dayOfWeek).name.capitalize();
      dayText = '$weekName $dayName';
    } else {
      dayText = 'day 1';
    }
    
    final timeStrings = times.map((time) {
      final hour = time['hour'] as int;
      final minute = time['minute'] as int;
      return _formatTime(hour, minute);
    }).toList();
    
    return 'Monthly on $dayText at ${timeStrings.join(', ')}';
  }

  String _getYearlyDisplay() {
    final month = scheduleData['month'] as int?;
    final dayOfMonth = scheduleData['dayOfMonth'] as int?;
    final times = (scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    if (times.isEmpty) return 'Yearly (no times set)';
    
    final monthName = month != null ? MonthOfYear.fromValue(month).name.capitalize() : 'January';
    final dayText = dayOfMonth != null ? 'day $dayOfMonth' : 'day 1';
    
    final timeStrings = times.map((time) {
      final hour = time['hour'] as int;
      final minute = time['minute'] as int;
      return _formatTime(hour, minute);
    }).toList();
    
    return 'Yearly on $monthName $dayText at ${timeStrings.join(', ')}';
  }

  String _getWeekdayDisplay() {
    final times = (scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (times.isEmpty) return 'Weekdays (no times set)';
    
    final timeStrings = times.map((time) {
      final hour = time['hour'] as int;
      final minute = time['minute'] as int;
      return _formatTime(hour, minute);
    }).toList();
    
    return 'Weekdays at ${timeStrings.join(', ')}';
  }

  String _getWeekendDisplay() {
    final times = (scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (times.isEmpty) return 'Weekends (no times set)';
    
    final timeStrings = times.map((time) {
      final hour = time['hour'] as int;
      final minute = time['minute'] as int;
      return _formatTime(hour, minute);
    }).toList();
    
    return 'Weekends at ${timeStrings.join(', ')}';
  }

  String _getCustomDisplay() {
    final description = scheduleData['description'] as String? ?? 'Custom schedule';
    return description;
  }

  String _getUnitName(TimeUnit unit, int count) {
    switch (unit) {
      case TimeUnit.minutes:
        return count == 1 ? 'minute' : 'minutes';
      case TimeUnit.hours:
        return count == 1 ? 'hour' : 'hours';
      case TimeUnit.days:
        return count == 1 ? 'day' : 'days';
      case TimeUnit.weeks:
        return count == 1 ? 'week' : 'weeks';
      case TimeUnit.months:
        return count == 1 ? 'month' : 'months';
      case TimeUnit.years:
        return count == 1 ? 'year' : 'years';
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }
}

enum ScheduleType {
  interval,    // Every N minutes/hours/days/weeks/months/years
  daily,       // Every day at specific times
  weekly,      // Specific days of week at specific times
  monthly,     // Specific day of month or week of month
  yearly,      // Specific month and day of year
  weekday,     // Monday-Friday
  weekend,     // Saturday-Sunday
  custom,      // Custom RRULE or complex pattern
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
