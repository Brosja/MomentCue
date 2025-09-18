import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'notification_schedule.dart';

class SimpleCheck {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String scheduleType;
  final bool enabled;
  final DateTime createdAt;
  final bool notificationsEnabled;
  final List<NotificationSchedule> notificationSchedules;
  final bool allowSnooze;
  final int maxSnoozes;

  SimpleCheck({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.scheduleType,
    this.enabled = true,
    required this.createdAt,
    this.notificationsEnabled = false,
    this.notificationSchedules = const [],
    this.allowSnooze = true,
    this.maxSnoozes = 3,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'scheduleType': scheduleType,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'notificationSchedules': notificationSchedules.map((ns) => ns.toJson()).toList(),
      'allowSnooze': allowSnooze,
      'maxSnoozes': maxSnoozes,
    };
  }

  factory SimpleCheck.fromJson(Map<String, dynamic> json) {
    return SimpleCheck(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      scheduleType: json['scheduleType'],
      enabled: json['enabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      notificationsEnabled: json['notificationsEnabled'] ?? false,
      notificationSchedules: (json['notificationSchedules'] as List<dynamic>?)
          ?.map((ns) => NotificationSchedule.fromJson(ns))
          .toList() ?? [],
      allowSnooze: json['allowSnooze'] ?? true,
      maxSnoozes: json['maxSnoozes'] ?? 3,
    );
  }
}

class CheckCategory {
  static const List<String> categories = [
    'Hydration',
    'Posture',
    'Medication',
    'Screen Break',
    'Breathing',
    'Exercise',
    'Custom',
  ];
}

class CheckScheduleType {
  static const List<String> types = [
    'One Time',
    'Daily',
    'Weekdays',
    'Weekly',
    'Monthly',
    'Yearly',
  ];
}

class NotificationTime {
  final int hour;
  final int minute;
  final List<int> weekdays; // 1=Monday, 7=Sunday, empty means all days
  final bool isEnabled;

  const NotificationTime({
    required this.hour,
    required this.minute,
    this.weekdays = const [],
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'weekdays': weekdays,
      'isEnabled': isEnabled,
    };
  }

  factory NotificationTime.fromJson(Map<String, dynamic> json) {
    return NotificationTime(
      hour: json['hour'],
      minute: json['minute'],
      weekdays: (json['weekdays'] as List<dynamic>?)?.cast<int>() ?? [],
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  String get displayTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $period';
  }

  String get weekdayString {
    if (weekdays.isEmpty) return 'Every day';
    
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekdays.length == 7) return 'Every day';
    if (weekdays.length == 5 && 
        weekdays.contains(1) && weekdays.contains(2) && weekdays.contains(3) && 
        weekdays.contains(4) && weekdays.contains(5)) {
      return 'Weekdays';
    }
    if (weekdays.length == 2 && 
        weekdays.contains(6) && weekdays.contains(7)) {
      return 'Weekends';
    }
    
    return weekdays.map((day) => dayNames[day - 1]).join(', ');
  }
}
