import 'package:rrule/rrule.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../models/check.dart';
import '../models/schedule.dart';
import 'time_service.dart';

class ScheduleService {
  static ScheduleService? _instance;
  static ScheduleService get instance => _instance ??= ScheduleService._();
  
  ScheduleService._();

  final TimeService _timeService = TimeService.instance;

  /// Generate the next N occurrences for a check
  List<ScheduleOccurrence> generateOccurrences({
    required Check check,
    required int count,
    DateTime? startFrom,
  }) {
    startFrom ??= _timeService.now();
    
    try {
      switch (check.scheduleType) {
        case ScheduleType.oneTime:
          return _generateOneTimeOccurrences(check, startFrom, count);
        case ScheduleType.daily:
          return _generateDailyOccurrences(check, startFrom, count);
        case ScheduleType.weekdays:
          return _generateWeekdaysOccurrences(check, startFrom, count);
        case ScheduleType.weekly:
          return _generateWeeklyOccurrences(check, startFrom, count);
        case ScheduleType.monthly:
          return _generateMonthlyOccurrences(check, startFrom, count);
        case ScheduleType.yearly:
          return _generateYearlyOccurrences(check, startFrom, count);
        case ScheduleType.rrule:
          return _generateRRuleOccurrences(check, startFrom, count);
        case ScheduleType.sequence:
          return _generateSequenceOccurrences(check, startFrom, count);
      }
    } catch (e) {
      throw ScheduleServiceException('Failed to generate occurrences: $e');
    }
  }

  /// Preview the next N occurrences for display (human-readable)
  List<DateTime> previewOccurrences({
    required Check check,
    required int count,
    DateTime? startFrom,
  }) {
    startFrom ??= _timeService.now();
    
    final occurrences = generateOccurrences(
      check: check,
      count: count,
      startFrom: startFrom,
    );
    
    return occurrences.map((o) => o.scheduledTime).toList();
  }

  /// Get natural language description of a schedule
  String getScheduleDescription(Check check) {
    try {
      switch (check.scheduleType) {
        case ScheduleType.oneTime:
          return _getOneTimeDescription(check);
        case ScheduleType.daily:
          return _getDailyDescription(check);
        case ScheduleType.weekdays:
          return _getWeekdaysDescription(check);
        case ScheduleType.weekly:
          return _getWeeklyDescription(check);
        case ScheduleType.monthly:
          return _getMonthlyDescription(check);
        case ScheduleType.yearly:
          return _getYearlyDescription(check);
        case ScheduleType.rrule:
          return _getRRuleDescription(check);
        case ScheduleType.sequence:
          return _getSequenceDescription(check);
      }
    } catch (e) {
      return 'Custom schedule';
    }
  }

  /// Validate RRULE string
  bool validateRRule(String rruleString) {
    try {
      RecurrenceRule.fromString(rruleString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Parse RRULE string and return human-readable description
  String parseRRuleDescription(String rruleString) {
    try {
      final rrule = RecurrenceRule.fromString(rruleString);
      return _rruleToHumanReadable(rrule);
    } catch (e) {
      return 'Invalid RRULE';
    }
  }

  /// Generate occurrences for one-time schedule
  List<ScheduleOccurrence> _generateOneTimeOccurrences(
    Check check,
    DateTime startFrom,
    int count,
  ) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['dateTime'] == null) {
      return [];
    }

    final scheduledTime = DateTime.parse(scheduleData['dateTime']);
    if (scheduledTime.isBefore(startFrom)) {
      return [];
    }

    return [
      ScheduleOccurrence(
        id: const Uuid().v4(),
        checkId: check.id,
        scheduledTime: scheduledTime,
      ),
    ];
  }

  /// Generate occurrences for daily schedule
  List<ScheduleOccurrence> _generateDailyOccurrences(
    Check check,
    DateTime startFrom,
    int count,
  ) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['time'] == null) {
      return [];
    }

    final time = scheduleData['time'];
    final hour = time['hour'] as int;
    final minute = time['minute'] as int;
    final interval = scheduleData['interval'] as int? ?? 1;

    final occurrences = <ScheduleOccurrence>[];
    var current = _timeService.startOfDay(startFrom);
    current = _timeService.localDateTime(
      current.year,
      current.month,
      current.day,
      hour,
      minute,
    );

    // If today's time has passed, start from tomorrow
    if (current.isBefore(startFrom)) {
      current = current.add(Duration(days: interval));
    }

    for (int i = 0; i < count; i++) {
      if (_isScheduledDate(current, check)) {
        occurrences.add(ScheduleOccurrence(
          id: const Uuid().v4(),
          checkId: check.id,
          scheduledTime: current,
        ));
      }
      current = current.add(Duration(days: interval));
    }

    return occurrences;
  }

  /// Generate occurrences for weekdays schedule
  List<ScheduleOccurrence> _generateWeekdaysOccurrences(
    Check check,
    DateTime startFrom,
    int count,
  ) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['time'] == null) {
      return [];
    }

    final time = scheduleData['time'];
    final hour = time['hour'] as int;
    final minute = time['minute'] as int;

    final occurrences = <ScheduleOccurrence>[];
    var current = _timeService.startOfDay(startFrom);
    
    while (occurrences.length < count) {
      // Check if current day is a weekday (Monday = 1, Friday = 5)
      if (current.weekday >= 1 && current.weekday <= 5) {
        final scheduledTime = _timeService.localDateTime(
          current.year,
          current.month,
          current.day,
          hour,
          minute,
        );

        if (scheduledTime.isAfter(startFrom) && _isScheduledDate(scheduledTime, check)) {
          occurrences.add(ScheduleOccurrence(
            id: const Uuid().v4(),
            checkId: check.id,
            scheduledTime: scheduledTime,
          ));
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return occurrences;
  }

  /// Generate occurrences for weekly schedule
  List<ScheduleOccurrence> _generateWeeklyOccurrences(
    Check check,
    DateTime startFrom,
    int count,
  ) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || 
        scheduleData['time'] == null || 
        scheduleData['weekdays'] == null) {
      return [];
    }

    final time = scheduleData['time'];
    final hour = time['hour'] as int;
    final minute = time['minute'] as int;
    final weekdays = (scheduleData['weekdays'] as List).cast<int>();
    final interval = scheduleData['interval'] as int? ?? 1;

    final occurrences = <ScheduleOccurrence>[];
    var current = _timeService.startOfDay(startFrom);
    
    while (occurrences.length < count) {
      if (weekdays.contains(current.weekday)) {
        final scheduledTime = _timeService.localDateTime(
          current.year,
          current.month,
          current.day,
          hour,
          minute,
        );

        if (scheduledTime.isAfter(startFrom) && _isScheduledDate(scheduledTime, check)) {
          occurrences.add(ScheduleOccurrence(
            id: const Uuid().v4(),
            checkId: check.id,
            scheduledTime: scheduledTime,
          ));
        }
      }
      current = current.add(Duration(days: interval));
    }

    return occurrences;
  }

  /// Generate occurrences for monthly schedule
  List<ScheduleOccurrence> _generateMonthlyOccurrences(
    Check check,
    DateTime startFrom,
    int count,
  ) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['time'] == null) {
      return [];
    }

    final time = scheduleData['time'];
    final hour = time['hour'] as int;
    final minute = time['minute'] as int;
    final dayOfMonth = scheduleData['dayOfMonth'] as int?;
    final weekOfMonth = scheduleData['weekOfMonth'] as int?;
    final dayOfWeek = scheduleData['dayOfWeek'] as int?;

    final occurrences = <ScheduleOccurrence>[];
    var current = _timeService.startOfMonth(startFrom);
    
    while (occurrences.length < count) {
      DateTime? scheduledTime;

      if (dayOfMonth != null) {
        // Monthly by day of month (e.g., 15th of each month)
        try {
          scheduledTime = _timeService.localDateTime(
            current.year,
            current.month,
            dayOfMonth,
            hour,
            minute,
          );
        } catch (e) {
          // Day doesn't exist in this month (e.g., Feb 30)
          scheduledTime = null;
        }
      } else if (weekOfMonth != null && dayOfWeek != null) {
        // Monthly by week and day (e.g., first Monday of each month)
        scheduledTime = _getNthWeekdayOfMonth(
          current.year,
          current.month,
          weekOfMonth,
          dayOfWeek,
          hour,
          minute,
        );
      }

      if (scheduledTime != null && 
          scheduledTime.isAfter(startFrom) && 
          _isScheduledDate(scheduledTime, check)) {
        occurrences.add(ScheduleOccurrence(
          id: const Uuid().v4(),
          checkId: check.id,
          scheduledTime: scheduledTime,
        ));
      }

      // Move to next month
      current = _timeService.localDateTime(
        current.month == 12 ? current.year + 1 : current.year,
        current.month == 12 ? 1 : current.month + 1,
        1,
      );
    }

    return occurrences;
  }

  /// Generate occurrences for yearly schedule
  List<ScheduleOccurrence> _generateYearlyOccurrences(
    Check check,
    DateTime startFrom,
    int count,
  ) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || 
        scheduleData['time'] == null ||
        scheduleData['month'] == null ||
        scheduleData['day'] == null) {
      return [];
    }

    final time = scheduleData['time'];
    final hour = time['hour'] as int;
    final minute = time['minute'] as int;
    final month = scheduleData['month'] as int;
    final day = scheduleData['day'] as int;

    final occurrences = <ScheduleOccurrence>[];
    var currentYear = startFrom.year;
    
    while (occurrences.length < count) {
      try {
        final scheduledTime = _timeService.localDateTime(
          currentYear,
          month,
          day,
          hour,
          minute,
        );

        if (scheduledTime.isAfter(startFrom) && _isScheduledDate(scheduledTime, check)) {
          occurrences.add(ScheduleOccurrence(
            id: const Uuid().v4(),
            checkId: check.id,
            scheduledTime: scheduledTime,
          ));
        }
      } catch (e) {
        // Date doesn't exist (e.g., Feb 29 in non-leap year)
      }

      currentYear++;
    }

    return occurrences;
  }

  /// Generate occurrences for RRULE schedule
  List<ScheduleOccurrence> _generateRRuleOccurrences(
    Check check,
    DateTime startFrom,
    int count,
  ) {
    if (check.rruleString == null) {
      return [];
    }

    try {
      final rrule = RecurrenceRule.fromString(check.rruleString!);
      final instances = rrule.getInstances(start: startFrom).take(count);

      return instances.map((dateTime) {
        return ScheduleOccurrence(
          id: const Uuid().v4(),
          checkId: check.id,
          scheduledTime: dateTime,
        );
      }).toList();
    } catch (e) {
      throw ScheduleServiceException('Invalid RRULE: ${check.rruleString}');
    }
  }

  /// Generate occurrences for sequence schedule
  List<ScheduleOccurrence> _generateSequenceOccurrences(
    Check check,
    DateTime startFrom,
    int count,
  ) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['intervals'] == null) {
      return [];
    }

    final intervalsData = scheduleData['intervals'] as List;
    final intervals = intervalsData
        .map((data) => SequenceInterval.fromJson(data))
        .toList();
    
    final startDate = scheduleData['startDate'] != null
        ? DateTime.parse(scheduleData['startDate'])
        : startFrom;

    if (intervals.isEmpty) {
      return [];
    }

    final occurrences = <ScheduleOccurrence>[];
    var current = startDate;
    var intervalIndex = 0;

    // Skip past occurrences that are before startFrom
    while (current.isBefore(startFrom)) {
      final interval = intervals[intervalIndex % intervals.length];
      current = current.add(interval.duration);
      intervalIndex++;
    }

    // Generate future occurrences
    for (int i = 0; i < count; i++) {
      if (_isScheduledDate(current, check)) {
        occurrences.add(ScheduleOccurrence(
          id: const Uuid().v4(),
          checkId: check.id,
          scheduledTime: current,
        ));
      }

      final interval = intervals[intervalIndex % intervals.length];
      current = current.add(interval.duration);
      intervalIndex++;
    }

    return occurrences;
  }

  /// Check if a date is scheduled (not in pause ranges or exceptions)
  bool _isScheduledDate(DateTime dateTime, Check check) {
    // Check pause ranges
    if (check.pausedRanges != null) {
      for (int i = 0; i < check.pausedRanges!.length; i += 2) {
        final start = check.pausedRanges![i];
        final end = i + 1 < check.pausedRanges!.length 
            ? check.pausedRanges![i + 1]
            : DateTime.now().add(const Duration(days: 365));
            
        if (dateTime.isAfter(start) && dateTime.isBefore(end)) {
          return false;
        }
      }
    }

    // Check skipped occurrences
    if (check.skippedOccurrences != null) {
      for (final skipped in check.skippedOccurrences!) {
        if (_timeService.isSameDay(dateTime, skipped)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Get the nth weekday of a month (e.g., first Monday)
  DateTime? _getNthWeekdayOfMonth(
    int year,
    int month,
    int weekOfMonth,
    int dayOfWeek,
    int hour,
    int minute,
  ) {
    try {
      final firstDayOfMonth = DateTime(year, month, 1);
      final firstWeekday = firstDayOfMonth.weekday;
      
      // Calculate days to add to get to the desired weekday
      int daysToAdd = (dayOfWeek - firstWeekday + 7) % 7;
      
      // Add weeks
      daysToAdd += (weekOfMonth - 1) * 7;
      
      final targetDate = firstDayOfMonth.add(Duration(days: daysToAdd));
      
      // Check if the date is still in the same month
      if (targetDate.month != month) {
        return null;
      }
      
      return DateTime(year, month, targetDate.day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  // Description methods
  String _getOneTimeDescription(Check check) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['dateTime'] == null) {
      return 'One-time reminder';
    }
    
    final dateTime = DateTime.parse(scheduleData['dateTime']);
    return 'Once on ${_timeService.formatLocal(dateTime, 'yyyy-MM-dd HH:mm')}';
  }

  String _getDailyDescription(Check check) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['time'] == null) {
      return 'Daily';
    }
    
    final time = scheduleData['time'];
    final interval = scheduleData['interval'] as int? ?? 1;
    final timeStr = '${time['hour'].toString().padLeft(2, '0')}:${time['minute'].toString().padLeft(2, '0')}';
    
    if (interval == 1) {
      return 'Daily at $timeStr';
    } else {
      return 'Every $interval days at $timeStr';
    }
  }

  String _getWeekdaysDescription(Check check) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['time'] == null) {
      return 'Weekdays';
    }
    
    final time = scheduleData['time'];
    final timeStr = '${time['hour'].toString().padLeft(2, '0')}:${time['minute'].toString().padLeft(2, '0')}';
    return 'Weekdays at $timeStr';
  }

  String _getWeeklyDescription(Check check) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || 
        scheduleData['time'] == null || 
        scheduleData['weekdays'] == null) {
      return 'Weekly';
    }
    
    final time = scheduleData['time'];
    final weekdays = (scheduleData['weekdays'] as List).cast<int>();
    final timeStr = '${time['hour'].toString().padLeft(2, '0')}:${time['minute'].toString().padLeft(2, '0')}';
    
    final dayNames = weekdays.map(_weekdayName).join(', ');
    return 'Weekly on $dayNames at $timeStr';
  }

  String _getMonthlyDescription(Check check) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['time'] == null) {
      return 'Monthly';
    }
    
    final time = scheduleData['time'];
    final timeStr = '${time['hour'].toString().padLeft(2, '0')}:${time['minute'].toString().padLeft(2, '0')}';
    
    if (scheduleData['dayOfMonth'] != null) {
      final day = scheduleData['dayOfMonth'];
      return 'Monthly on the ${_ordinal(day)} at $timeStr';
    } else if (scheduleData['weekOfMonth'] != null && scheduleData['dayOfWeek'] != null) {
      final week = _ordinal(scheduleData['weekOfMonth']);
      final day = _weekdayName(scheduleData['dayOfWeek']);
      return 'Monthly on the $week $day at $timeStr';
    }
    
    return 'Monthly at $timeStr';
  }

  String _getYearlyDescription(Check check) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || 
        scheduleData['time'] == null ||
        scheduleData['month'] == null ||
        scheduleData['day'] == null) {
      return 'Yearly';
    }
    
    final time = scheduleData['time'];
    final month = scheduleData['month'];
    final day = scheduleData['day'];
    final timeStr = '${time['hour'].toString().padLeft(2, '0')}:${time['minute'].toString().padLeft(2, '0')}';
    
    return 'Yearly on ${_monthName(month)} ${_ordinal(day)} at $timeStr';
  }

  String _getRRuleDescription(Check check) {
    if (check.rruleString == null) {
      return 'Custom recurrence';
    }
    
    try {
      final rrule = RecurrenceRule.fromString(check.rruleString!);
      return _rruleToHumanReadable(rrule);
    } catch (e) {
      return 'Custom recurrence (${check.rruleString})';
    }
  }

  String _getSequenceDescription(Check check) {
    final scheduleData = check.scheduleData;
    if (scheduleData == null || scheduleData['intervals'] == null) {
      return 'Custom sequence';
    }
    
    final intervalsData = scheduleData['intervals'] as List;
    final intervals = intervalsData
        .map((data) => SequenceInterval.fromJson(data))
        .toList();
    
    if (intervals.isEmpty) {
      return 'Custom sequence';
    }
    
    final description = intervals
        .take(3)
        .map((interval) => interval.displayString)
        .join(', ');
    
    final suffix = intervals.length > 3 ? '...' : '';
    return 'Sequence: $description$suffix (repeating)';
  }

  String _rruleToHumanReadable(RecurrenceRule rrule) {
    final freq = rrule.frequency;
    final interval = rrule.interval;
    
    String description = '';
    
    switch (freq) {
      case Frequency.daily:
        description = interval == 1 ? 'Daily' : 'Every $interval days';
        break;
      case Frequency.weekly:
        description = interval == 1 ? 'Weekly' : 'Every $interval weeks';
        if (rrule.byWeekDays.isNotEmpty) {
          final days = rrule.byWeekDays.map((wd) => _weekdayName(wd.day)).join(', ');
          description += ' on $days';
        }
        break;
      case Frequency.monthly:
        description = interval == 1 ? 'Monthly' : 'Every $interval months';
        break;
      case Frequency.yearly:
        description = interval == 1 ? 'Yearly' : 'Every $interval years';
        break;
      default:
        description = 'Custom recurrence';
    }
    
    if (rrule.count != null) {
      description += ' (${rrule.count} times)';
    } else if (rrule.until != null) {
      description += ' (until ${_timeService.formatLocal(rrule.until!, 'yyyy-MM-dd')})';
    }
    
    return description;
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  String _monthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return 'Unknown';
    }
  }

  String _ordinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }
}

class ScheduleServiceException implements Exception {
  final String message;
  ScheduleServiceException(this.message);

  @override
  String toString() => 'ScheduleServiceException: $message';
}
