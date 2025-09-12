import 'package:hive/hive.dart';

part 'schedule.g.dart';

@HiveType(typeId: 5)
class Schedule extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late ScheduleType type;

  @HiveField(2)
  DateTime? startDate;

  @HiveField(3)
  DateTime? endDate;

  @HiveField(4)
  String? rruleString;

  @HiveField(5)
  List<SequenceInterval>? sequenceIntervals;

  @HiveField(6)
  Map<String, dynamic>? presetData;

  @HiveField(7)
  String? timezoneName;

  @HiveField(8)
  bool anchorToLocalTime = true;

  @HiveField(9)
  List<DateTime>? exceptions;

  Schedule({
    required this.id,
    required this.type,
    this.startDate,
    this.endDate,
    this.rruleString,
    this.sequenceIntervals,
    this.presetData,
    this.timezoneName,
    this.anchorToLocalTime = true,
    this.exceptions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'rruleString': rruleString,
      'sequenceIntervals': sequenceIntervals?.map((e) => e.toJson()).toList(),
      'presetData': presetData,
      'timezoneName': timezoneName,
      'anchorToLocalTime': anchorToLocalTime,
      'exceptions': exceptions?.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      type: ScheduleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ScheduleType.oneTime,
      ),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'])
          : null,
      rruleString: json['rruleString'],
      sequenceIntervals: json['sequenceIntervals']
          ?.map<SequenceInterval>((e) => SequenceInterval.fromJson(e))
          .toList(),
      presetData: json['presetData'],
      timezoneName: json['timezoneName'],
      anchorToLocalTime: json['anchorToLocalTime'] ?? true,
      exceptions: json['exceptions']
          ?.map<DateTime>((e) => DateTime.parse(e))
          .toList(),
    );
  }
}

@HiveType(typeId: 6)
enum ScheduleType {
  @HiveField(0)
  oneTime,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekdays,
  @HiveField(3)
  weekly,
  @HiveField(4)
  monthly,
  @HiveField(5)
  yearly,
  @HiveField(6)
  rrule,
  @HiveField(7)
  sequence,
}

@HiveType(typeId: 7)
class SequenceInterval extends HiveObject {
  @HiveField(0)
  late int value;

  @HiveField(1)
  late TimeUnit unit;

  @HiveField(2)
  int order = 0;

  SequenceInterval({
    required this.value,
    required this.unit,
    this.order = 0,
  });

  Duration get duration {
    switch (unit) {
      case TimeUnit.minutes:
        return Duration(minutes: value);
      case TimeUnit.hours:
        return Duration(hours: value);
      case TimeUnit.days:
        return Duration(days: value);
      case TimeUnit.weeks:
        return Duration(days: value * 7);
      case TimeUnit.months:
        return Duration(days: value * 30); // Approximate
      case TimeUnit.years:
        return Duration(days: value * 365); // Approximate
    }
  }

  String get displayString {
    final unitName = unit.name;
    return '$value ${value == 1 ? unitName.substring(0, unitName.length - 1) : unitName}';
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit.name,
      'order': order,
    };
  }

  factory SequenceInterval.fromJson(Map<String, dynamic> json) {
    return SequenceInterval(
      value: json['value'],
      unit: TimeUnit.values.firstWhere(
        (e) => e.name == json['unit'],
        orElse: () => TimeUnit.days,
      ),
      order: json['order'] ?? 0,
    );
  }
}

@HiveType(typeId: 8)
enum TimeUnit {
  @HiveField(0)
  minutes,
  @HiveField(1)
  hours,
  @HiveField(2)
  days,
  @HiveField(3)
  weeks,
  @HiveField(4)
  months,
  @HiveField(5)
  years,
}

@HiveType(typeId: 9)
class ScheduleOccurrence extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String checkId;

  @HiveField(2)
  late DateTime scheduledTime;

  @HiveField(3)
  DateTime? completedTime;

  @HiveField(4)
  DateTime? snoozeUntil;

  @HiveField(5)
  int snoozeCount = 0;

  @HiveField(6)
  late OccurrenceStatus status;

  @HiveField(7)
  String? note;

  @HiveField(8)
  Map<String, dynamic>? metadata;

  ScheduleOccurrence({
    required this.id,
    required this.checkId,
    required this.scheduledTime,
    this.completedTime,
    this.snoozeUntil,
    this.snoozeCount = 0,
    this.status = OccurrenceStatus.pending,
    this.note,
    this.metadata,
  });

  bool get isCompleted => status == OccurrenceStatus.completed;
  bool get isMissed => status == OccurrenceStatus.missed;
  bool get isSkipped => status == OccurrenceStatus.skipped;
  bool get isSnoozed => status == OccurrenceStatus.snoozed;
  bool get isPending => status == OccurrenceStatus.pending;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checkId': checkId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'completedTime': completedTime?.toIso8601String(),
      'snoozeUntil': snoozeUntil?.toIso8601String(),
      'snoozeCount': snoozeCount,
      'status': status.name,
      'note': note,
      'metadata': metadata,
    };
  }

  factory ScheduleOccurrence.fromJson(Map<String, dynamic> json) {
    return ScheduleOccurrence(
      id: json['id'],
      checkId: json['checkId'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      completedTime: json['completedTime'] != null
          ? DateTime.parse(json['completedTime'])
          : null,
      snoozeUntil: json['snoozeUntil'] != null
          ? DateTime.parse(json['snoozeUntil'])
          : null,
      snoozeCount: json['snoozeCount'] ?? 0,
      status: OccurrenceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OccurrenceStatus.pending,
      ),
      note: json['note'],
      metadata: json['metadata'],
    );
  }
}

@HiveType(typeId: 10)
enum OccurrenceStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed,
  @HiveField(2)
  missed,
  @HiveField(3)
  skipped,
  @HiveField(4)
  snoozed,
}

// Preset schedule configurations
class PresetSchedules {
  static Map<String, dynamic> daily({required TimeOfDay time}) {
    return {
      'type': 'daily',
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      },
    };
  }

  static Map<String, dynamic> weekdays({required TimeOfDay time}) {
    return {
      'type': 'weekdays',
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      },
      'weekdays': [1, 2, 3, 4, 5], // Monday to Friday
    };
  }

  static Map<String, dynamic> weekly({
    required TimeOfDay time,
    required List<int> weekdays,
  }) {
    return {
      'type': 'weekly',
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      },
      'weekdays': weekdays,
    };
  }

  static Map<String, dynamic> monthly({
    required TimeOfDay time,
    int? dayOfMonth,
    int? weekOfMonth,
    int? dayOfWeek,
  }) {
    return {
      'type': 'monthly',
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      },
      if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      if (weekOfMonth != null) 'weekOfMonth': weekOfMonth,
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
    };
  }

  static Map<String, dynamic> yearly({
    required TimeOfDay time,
    required int month,
    required int day,
  }) {
    return {
      'type': 'yearly',
      'time': {
        'hour': time.hour,
        'minute': time.minute,
      },
      'month': month,
      'day': day,
    };
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  Map<String, int> toJson() => {'hour': hour, 'minute': minute};

  factory TimeOfDay.fromJson(Map<String, dynamic> json) {
    return TimeOfDay(hour: json['hour'], minute: json['minute']);
  }

  @override
  String toString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
