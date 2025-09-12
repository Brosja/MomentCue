// Simple RRULE implementation for basic recurrence rules
// This is a simplified version - in production you'd use a full RFC5545 implementation

enum Frequency {
  daily,
  weekly,
  monthly,
  yearly,
}

class ByWeekDay {
  final int day; // 1=Monday, 7=Sunday
  final int? week; // nth occurrence (e.g., 1st Monday)

  ByWeekDay(this.day, [this.week]);
}

class RecurrenceRule {
  final Frequency frequency;
  final int interval;
  final DateTime? until;
  final int? count;
  final List<ByWeekDay> byWeekDays;
  final List<int> byMonthDay;
  final List<int> byMonth;

  RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.until,
    this.count,
    this.byWeekDays = const [],
    this.byMonthDay = const [],
    this.byMonth = const [],
  });

  factory RecurrenceRule.fromString(String rruleString) {
    final parts = rruleString.split(';');
    final rules = <String, String>{};
    
    for (final part in parts) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        rules[keyValue[0]] = keyValue[1];
      }
    }

    final freq = _parseFrequency(rules['FREQ'] ?? 'DAILY');
    final interval = int.tryParse(rules['INTERVAL'] ?? '1') ?? 1;
    final until = rules['UNTIL'] != null ? DateTime.tryParse(rules['UNTIL']!) : null;
    final count = int.tryParse(rules['COUNT'] ?? '') ?? null;

    return RecurrenceRule(
      frequency: freq,
      interval: interval,
      until: until,
      count: count,
    );
  }

  static Frequency _parseFrequency(String freq) {
    switch (freq.toUpperCase()) {
      case 'DAILY':
        return Frequency.daily;
      case 'WEEKLY':
        return Frequency.weekly;
      case 'MONTHLY':
        return Frequency.monthly;
      case 'YEARLY':
        return Frequency.yearly;
      default:
        return Frequency.daily;
    }
  }

  Iterable<DateTime> getInstances({required DateTime start}) sync* {
    var current = start;
    var instances = 0;

    while (true) {
      // Check if we've reached the limit
      if (count != null && instances >= count!) break;
      if (until != null && current.isAfter(until!)) break;

      yield current;
      instances++;

      // Calculate next occurrence
      switch (frequency) {
        case Frequency.daily:
          current = current.add(Duration(days: interval));
          break;
        case Frequency.weekly:
          current = current.add(Duration(days: 7 * interval));
          break;
        case Frequency.monthly:
          current = DateTime(
            current.month == 12 ? current.year + 1 : current.year,
            current.month == 12 ? 1 : current.month + interval,
            current.day,
            current.hour,
            current.minute,
            current.second,
          );
          break;
        case Frequency.yearly:
          current = DateTime(
            current.year + interval,
            current.month,
            current.day,
            current.hour,
            current.minute,
            current.second,
          );
          break;
      }
    }
  }

  @override
  String toString() {
    final parts = <String>[];
    
    parts.add('FREQ=${frequency.name.toUpperCase()}');
    
    if (interval != 1) {
      parts.add('INTERVAL=$interval');
    }
    
    if (until != null) {
      parts.add('UNTIL=${until!.toIso8601String()}');
    }
    
    if (count != null) {
      parts.add('COUNT=$count');
    }
    
    return parts.join(';');
  }
}
