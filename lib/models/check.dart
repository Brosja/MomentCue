import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'schedule.dart';

part 'check.g.dart';

@HiveType(typeId: 0)
class Check extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  late CheckCategory category;

  @HiveField(4)
  late ScheduleType scheduleType;

  @HiveField(5)
  Map<String, dynamic>? scheduleData;

  @HiveField(6)
  String? rruleString;

  @HiveField(7)
  late bool enabled;

  @HiveField(8)
  late SnoozePolicy snoozePolicy;

  @HiveField(9)
  late DateTime createdAt;

  @HiveField(10)
  late DateTime updatedAt;

  @HiveField(11)
  CheckAnalytics? analytics;

  @HiveField(12)
  String? iconName;

  @HiveField(13)
  int? colorValue;

  @HiveField(14)
  List<String>? tags;

  @HiveField(15)
  bool isArchived = false;

  @HiveField(16)
  List<DateTime>? pausedRanges;

  @HiveField(17)
  List<DateTime>? skippedOccurrences;

  Check({
    String? id,
    required this.title,
    this.description,
    required this.category,
    required this.scheduleType,
    this.scheduleData,
    this.rruleString,
    this.enabled = true,
    SnoozePolicy? snoozePolicy,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.analytics,
    this.iconName,
    this.colorValue,
    this.tags,
    this.isArchived = false,
    this.pausedRanges,
    this.skippedOccurrences,
  }) {
    this.id = id ?? const Uuid().v4();
    this.snoozePolicy = snoozePolicy ?? SnoozePolicy.defaultPolicy();
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
    this.analytics ??= CheckAnalytics();
  }

  void updateAnalytics({
    bool? completed,
    DateTime? responseTime,
    bool? missed,
  }) {
    analytics ??= CheckAnalytics();
    
    if (completed == true) {
      analytics!.totalCompleted++;
      if (responseTime != null) {
        analytics!.addResponseTime(responseTime);
      }
      analytics!.updateStreak(true);
    } else if (missed == true) {
      analytics!.totalMissed++;
      analytics!.updateStreak(false);
    }
    
    analytics!.totalScheduled++;
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'scheduleType': scheduleType.name,
      'scheduleData': scheduleData,
      'rruleString': rruleString,
      'enabled': enabled,
      'snoozePolicy': snoozePolicy.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'analytics': analytics?.toJson(),
      'iconName': iconName,
      'colorValue': colorValue,
      'tags': tags,
      'isArchived': isArchived,
      'pausedRanges': pausedRanges?.map((e) => e.toIso8601String()).toList(),
      'skippedOccurrences': skippedOccurrences?.map((e) => e.toIso8601String()).toList(),
    };
  }

  factory Check.fromJson(Map<String, dynamic> json) {
    return Check(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: CheckCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => CheckCategory.custom,
      ),
      scheduleType: ScheduleType.values.firstWhere(
        (e) => e.name == json['scheduleType'],
        orElse: () => ScheduleType.oneTime,
      ),
      scheduleData: json['scheduleData'],
      rruleString: json['rruleString'],
      enabled: json['enabled'] ?? true,
      snoozePolicy: json['snoozePolicy'] != null
          ? SnoozePolicy.fromJson(json['snoozePolicy'])
          : SnoozePolicy.defaultPolicy(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      analytics: json['analytics'] != null
          ? CheckAnalytics.fromJson(json['analytics'])
          : null,
      iconName: json['iconName'],
      colorValue: json['colorValue'],
      tags: json['tags']?.cast<String>(),
      isArchived: json['isArchived'] ?? false,
      pausedRanges: json['pausedRanges']
          ?.map<DateTime>((e) => DateTime.parse(e))
          .toList(),
      skippedOccurrences: json['skippedOccurrences']
          ?.map<DateTime>((e) => DateTime.parse(e))
          .toList(),
    );
  }
}

@HiveType(typeId: 1)
enum CheckCategory {
  @HiveField(0)
  hydration,
  @HiveField(1)
  posture,
  @HiveField(2)
  medication,
  @HiveField(3)
  screenBreak,
  @HiveField(4)
  breathing,
  @HiveField(5)
  exercise,
  @HiveField(6)
  custom,
}

// ScheduleType is now imported from schedule.dart

@HiveType(typeId: 3)
class SnoozePolicy extends HiveObject {
  @HiveField(0)
  late bool allowSnooze;

  @HiveField(1)
  late int maxSnoozes;

  @HiveField(2)
  late List<int> snoozeOptions; // in minutes

  @HiveField(3)
  late int defaultSnooze; // in minutes

  SnoozePolicy({
    required this.allowSnooze,
    required this.maxSnoozes,
    required this.snoozeOptions,
    required this.defaultSnooze,
  });

  factory SnoozePolicy.defaultPolicy() {
    return SnoozePolicy(
      allowSnooze: true,
      maxSnoozes: 3,
      snoozeOptions: [5, 10, 15, 30, 60],
      defaultSnooze: 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowSnooze': allowSnooze,
      'maxSnoozes': maxSnoozes,
      'snoozeOptions': snoozeOptions,
      'defaultSnooze': defaultSnooze,
    };
  }

  factory SnoozePolicy.fromJson(Map<String, dynamic> json) {
    return SnoozePolicy(
      allowSnooze: json['allowSnooze'] ?? true,
      maxSnoozes: json['maxSnoozes'] ?? 3,
      snoozeOptions: json['snoozeOptions']?.cast<int>() ?? [5, 10, 15, 30, 60],
      defaultSnooze: json['defaultSnooze'] ?? 10,
    );
  }
}

@HiveType(typeId: 4)
class CheckAnalytics extends HiveObject {
  @HiveField(0)
  int totalScheduled = 0;

  @HiveField(1)
  int totalCompleted = 0;

  @HiveField(2)
  int totalMissed = 0;

  @HiveField(3)
  List<int> responseTimes = []; // in seconds

  @HiveField(4)
  int currentStreak = 0;

  @HiveField(5)
  int bestStreak = 0;

  @HiveField(6)
  DateTime? lastCompletedAt;

  @HiveField(7)
  Map<String, int> weeklyCompletions = {}; // week string -> count

  @HiveField(8)
  Map<String, int> monthlyCompletions = {}; // month string -> count

  CheckAnalytics();

  double get completionRate {
    if (totalScheduled == 0) return 0.0;
    return totalCompleted / totalScheduled;
  }

  double get averageResponseTime {
    if (responseTimes.isEmpty) return 0.0;
    return responseTimes.reduce((a, b) => a + b) / responseTimes.length;
  }

  void addResponseTime(DateTime responseTime) {
    final scheduledTime = responseTime.subtract(Duration(seconds: responseTimes.length));
    final responseSeconds = responseTime.difference(scheduledTime).inSeconds;
    responseTimes.add(responseSeconds);
    
    // Keep only last 100 response times to prevent memory issues
    if (responseTimes.length > 100) {
      responseTimes.removeAt(0);
    }
  }

  void updateStreak(bool completed) {
    if (completed) {
      currentStreak++;
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }
      lastCompletedAt = DateTime.now();
    } else {
      currentStreak = 0;
    }
  }

  void updateWeeklyStats(DateTime date) {
    final weekKey = '${date.year}-W${_getWeekOfYear(date)}';
    weeklyCompletions[weekKey] = (weeklyCompletions[weekKey] ?? 0) + 1;
  }

  void updateMonthlyStats(DateTime date) {
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    monthlyCompletions[monthKey] = (monthlyCompletions[monthKey] ?? 0) + 1;
  }

  int _getWeekOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstWeek = startOfYear.add(Duration(days: 7 - startOfYear.weekday + 1));
    if (date.isBefore(firstWeek)) return 1;
    return ((date.difference(firstWeek).inDays / 7).floor() + 2);
  }

  Map<String, dynamic> toJson() {
    return {
      'totalScheduled': totalScheduled,
      'totalCompleted': totalCompleted,
      'totalMissed': totalMissed,
      'responseTimes': responseTimes,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'weeklyCompletions': weeklyCompletions,
      'monthlyCompletions': monthlyCompletions,
    };
  }

  factory CheckAnalytics.fromJson(Map<String, dynamic> json) {
    return CheckAnalytics()
      ..totalScheduled = json['totalScheduled'] ?? 0
      ..totalCompleted = json['totalCompleted'] ?? 0
      ..totalMissed = json['totalMissed'] ?? 0
      ..responseTimes = json['responseTimes']?.cast<int>() ?? []
      ..currentStreak = json['currentStreak'] ?? 0
      ..bestStreak = json['bestStreak'] ?? 0
      ..lastCompletedAt = json['lastCompletedAt'] != null
          ? DateTime.parse(json['lastCompletedAt'])
          : null
      ..weeklyCompletions = json['weeklyCompletions']?.cast<String, int>() ?? {}
      ..monthlyCompletions = json['monthlyCompletions']?.cast<String, int>() ?? {};
  }
}
