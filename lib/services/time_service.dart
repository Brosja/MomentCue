import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class TimeService {
  static TimeService? _instance;
  static TimeService get instance => _instance ??= TimeService._();
  
  TimeService._();

  tz.Location? _localLocation;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Get the device's timezone
      final timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      _localLocation = tz.getLocation(timeZoneName);
      _isInitialized = true;
    } catch (e) {
      // Fallback to UTC if there's an error
      _localLocation = tz.UTC;
      _isInitialized = true;
      throw TimeServiceException('Failed to initialize timezone: $e');
    }
  }

  tz.Location get localLocation {
    if (!_isInitialized) {
      throw TimeServiceException('TimeService not initialized');
    }
    return _localLocation!;
  }

  String get localTimeZoneName {
    return localLocation.name;
  }

  /// Convert a DateTime to the local timezone
  tz.TZDateTime toLocal(DateTime dateTime) {
    if (dateTime is tz.TZDateTime) {
      return dateTime.toLocal() as tz.TZDateTime;
    }
    return tz.TZDateTime.from(dateTime, localLocation);
  }

  /// Convert a DateTime to a specific timezone
  tz.TZDateTime toTimezone(DateTime dateTime, String timezoneName) {
    final location = tz.getLocation(timezoneName);
    if (dateTime is tz.TZDateTime) {
      return dateTime.toTimeZone(location);
    }
    return tz.TZDateTime.from(dateTime, location);
  }

  /// Create a TZDateTime in local timezone
  tz.TZDateTime localDateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    return tz.TZDateTime(
      localLocation,
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  /// Create a TZDateTime in a specific timezone
  tz.TZDateTime dateTimeInTimezone(
    String timezoneName,
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) {
    final location = tz.getLocation(timezoneName);
    return tz.TZDateTime(
      location,
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    );
  }

  /// Get the current time in local timezone
  tz.TZDateTime now() {
    return tz.TZDateTime.now(localLocation);
  }

  /// Get the current time in a specific timezone
  tz.TZDateTime nowInTimezone(String timezoneName) {
    final location = tz.getLocation(timezoneName);
    return tz.TZDateTime.now(location);
  }

  /// Check if daylight saving time is active for the given date
  bool isDaylightSavingTime(DateTime dateTime) {
    final tzDateTime = toLocal(dateTime);
    return localLocation.isDst(tzDateTime.millisecondsSinceEpoch);
  }

  /// Get the UTC offset for the local timezone at a specific date
  Duration getUtcOffset(DateTime dateTime) {
    final tzDateTime = toLocal(dateTime);
    return Duration(milliseconds: tzDateTime.timeZoneOffset.inMilliseconds);
  }

  /// Convert local wall clock time to scheduled time considering timezone anchoring
  tz.TZDateTime scheduleTime({
    required DateTime baseTime,
    required bool anchorToLocalTime,
    String? originalTimezone,
  }) {
    if (anchorToLocalTime) {
      // Always trigger at the same wall clock time in current timezone
      return toLocal(baseTime);
    } else if (originalTimezone != null) {
      // Keep the same absolute time (relative to original timezone)
      return toTimezone(baseTime, originalTimezone);
    } else {
      // Default to local time
      return toLocal(baseTime);
    }
  }

  /// Handle timezone changes (when user travels or changes timezone)
  Future<void> handleTimezoneChange() async {
    try {
      final newTimeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      final newLocation = tz.getLocation(newTimeZoneName);
      
      if (newLocation.name != _localLocation?.name) {
        _localLocation = newLocation;
        // Notify about timezone change so schedules can be recalculated
        _notifyTimezoneChange(newLocation.name);
      }
    } catch (e) {
      throw TimeServiceException('Failed to handle timezone change: $e');
    }
  }

  void _notifyTimezoneChange(String newTimezone) {
    // This could be implemented with a stream or callback
    // For now, we'll just update the location
    // In a full implementation, this would trigger schedule recalculation
  }

  /// Format a DateTime for display in local timezone
  String formatLocal(DateTime dateTime, String pattern) {
    final localTime = toLocal(dateTime);
    return _formatDateTime(localTime, pattern);
  }

  /// Format a DateTime for display in a specific timezone
  String formatInTimezone(DateTime dateTime, String timezoneName, String pattern) {
    final zonedTime = toTimezone(dateTime, timezoneName);
    return _formatDateTime(zonedTime, pattern);
  }

  String _formatDateTime(tz.TZDateTime dateTime, String pattern) {
    // Simple formatting - in a real app you'd use intl package
    switch (pattern) {
      case 'HH:mm':
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      case 'yyyy-MM-dd':
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      case 'yyyy-MM-dd HH:mm':
        return '${formatLocal(dateTime, 'yyyy-MM-dd')} ${formatLocal(dateTime, 'HH:mm')}';
      default:
        return dateTime.toString();
    }
  }

  /// Get start of day in local timezone
  tz.TZDateTime startOfDay(DateTime dateTime) {
    final local = toLocal(dateTime);
    return tz.TZDateTime(localLocation, local.year, local.month, local.day);
  }

  /// Get end of day in local timezone
  tz.TZDateTime endOfDay(DateTime dateTime) {
    return startOfDay(dateTime).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
  }

  /// Get start of week (Monday) in local timezone
  tz.TZDateTime startOfWeek(DateTime dateTime) {
    final local = toLocal(dateTime);
    final daysFromMonday = local.weekday - 1;
    return startOfDay(local.subtract(Duration(days: daysFromMonday)));
  }

  /// Get start of month in local timezone
  tz.TZDateTime startOfMonth(DateTime dateTime) {
    final local = toLocal(dateTime);
    return tz.TZDateTime(localLocation, local.year, local.month, 1);
  }

  /// Get start of year in local timezone
  tz.TZDateTime startOfYear(DateTime dateTime) {
    final local = toLocal(dateTime);
    return tz.TZDateTime(localLocation, local.year, 1, 1);
  }

  /// Check if two dates are on the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    final local1 = toLocal(date1);
    final local2 = toLocal(date2);
    return local1.year == local2.year &&
           local1.month == local2.month &&
           local1.day == local2.day;
  }

  /// Check if a date is today
  bool isToday(DateTime date) {
    return isSameDay(date, now());
  }

  /// Check if a date is tomorrow
  bool isTomorrow(DateTime date) {
    final tomorrow = now().add(const Duration(days: 1));
    return isSameDay(date, tomorrow);
  }

  /// Check if a date is yesterday
  bool isYesterday(DateTime date) {
    final yesterday = now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Get a human-readable relative time string
  String getRelativeTimeString(DateTime dateTime) {
    final now = this.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      // Past
      final absDifference = difference.abs();
      if (absDifference.inMinutes < 1) {
        return 'Just now';
      } else if (absDifference.inHours < 1) {
        return '${absDifference.inMinutes} min ago';
      } else if (absDifference.inDays < 1) {
        return '${absDifference.inHours} hours ago';
      } else if (absDifference.inDays < 7) {
        return '${absDifference.inDays} days ago';
      } else {
        return formatLocal(dateTime, 'yyyy-MM-dd');
      }
    } else {
      // Future
      if (difference.inMinutes < 1) {
        return 'Now';
      } else if (difference.inHours < 1) {
        return 'In ${difference.inMinutes} min';
      } else if (difference.inDays < 1) {
        return 'In ${difference.inHours} hours';
      } else if (difference.inDays < 7) {
        return 'In ${difference.inDays} days';
      } else {
        return formatLocal(dateTime, 'yyyy-MM-dd');
      }
    }
  }

  /// List all available timezones
  List<String> getAllTimezones() {
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  /// Get timezone display name
  String getTimezoneDisplayName(String timezoneName) {
    try {
      final location = tz.getLocation(timezoneName);
      final now = tz.TZDateTime.now(location);
      final offset = now.timeZoneOffset;
      final offsetString = '${offset.isNegative ? '-' : '+'}${offset.inHours.abs().toString().padLeft(2, '0')}:${(offset.inMinutes.abs() % 60).toString().padLeft(2, '0')}';
      return '$timezoneName (UTC$offsetString)';
    } catch (e) {
      return timezoneName;
    }
  }

  void dispose() {
    _isInitialized = false;
    _localLocation = null;
  }
}

class TimeServiceException implements Exception {
  final String message;
  TimeServiceException(this.message);

  @override
  String toString() => 'TimeServiceException: $message';
}
