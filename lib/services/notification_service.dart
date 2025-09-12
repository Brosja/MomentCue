import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/check.dart';
import '../models/schedule.dart';
import 'time_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Function(String)? _onNotificationTap;
  Function(String, String)? _onNotificationAction;

  Future<void> initialize({
    Function(String)? onNotificationTap,
    Function(String, String)? onNotificationAction,
  }) async {
    if (_isInitialized) return;

    _onNotificationTap = onNotificationTap;
    _onNotificationAction = onNotificationAction;

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: null,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Request permissions
    await requestPermissions();

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      // Request notification permission for Android 13+
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    }
    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    if (Platform.isIOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.checkPermissions();
      return result?.isEnabled ?? false;
    } else if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    }
    return true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    if (payload != null) {
      if (actionId != null) {
        _onNotificationAction?.call(payload, actionId);
      } else {
        _onNotificationTap?.call(payload);
      }
    }
  }

  /// Schedule a notification for a check occurrence
  Future<void> scheduleNotification({
    required String id,
    required Check check,
    required ScheduleOccurrence occurrence,
    required tz.TZDateTime scheduledTime,
  }) async {
    if (!_isInitialized) {
      throw NotificationServiceException('NotificationService not initialized');
    }

    try {
      final notificationId = id.hashCode;
      
      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        'momentcue_reminders',
        'Health Check Reminders',
        channelDescription: 'Notifications for your health check reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        actions: _buildAndroidActions(check.snoozePolicy),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      final iOSDetails = DarwinNotificationDetails(
        categoryIdentifier: 'momentcue_reminder',
        interruptionLevel: InterruptionLevel.active,
      );

      final platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Create notification content
      final title = check.title;
      final body = _buildNotificationBody(check);
      final payload = _buildNotificationPayload(check.id, occurrence.id);

      // Schedule the notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTime,
        platformChannelSpecifics,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      throw NotificationServiceException('Failed to schedule notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(String id) async {
    if (!_isInitialized) {
      throw NotificationServiceException('NotificationService not initialized');
    }

    try {
      final notificationId = id.hashCode;
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
    } catch (e) {
      throw NotificationServiceException('Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications for a specific check
  Future<void> cancelNotificationsForCheck(String checkId) async {
    if (!_isInitialized) {
      throw NotificationServiceException('NotificationService not initialized');
    }

    try {
      // Get all pending notifications
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      
      // Cancel notifications that belong to this check
      for (final notification in pendingNotifications) {
        if (notification.payload?.contains(checkId) == true) {
          await _flutterLocalNotificationsPlugin.cancel(notification.id);
        }
      }
    } catch (e) {
      throw NotificationServiceException('Failed to cancel notifications for check: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      throw NotificationServiceException('NotificationService not initialized');
    }

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      throw NotificationServiceException('Failed to cancel all notifications: $e');
    }
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) {
      throw NotificationServiceException('NotificationService not initialized');
    }

    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      throw NotificationServiceException('Failed to get pending notifications: $e');
    }
  }

  /// Show an immediate notification (for testing or immediate feedback)
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      throw NotificationServiceException('NotificationService not initialized');
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'momentcue_immediate',
        'Immediate Notifications',
        channelDescription: 'Immediate notifications from MomentCue',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iOSDetails = DarwinNotificationDetails();

      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        id.hashCode,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      throw NotificationServiceException('Failed to show notification: $e');
    }
  }

  /// Reschedule all notifications (useful after timezone changes or boot)
  Future<void> rescheduleAllNotifications(List<ScheduleOccurrence> occurrences) async {
    if (!_isInitialized) {
      throw NotificationServiceException('NotificationService not initialized');
    }

    try {
      // Cancel all existing notifications
      await cancelAllNotifications();

      // Reschedule notifications for future occurrences
      final now = TimeService.instance.now();
      final futureOccurrences = occurrences
          .where((occurrence) => 
              occurrence.scheduledTime.isAfter(now) && 
              occurrence.status == OccurrenceStatus.pending)
          .toList();

      // Limit to next 64 notifications (Android limit)
      final limitedOccurrences = futureOccurrences.take(64).toList();

      for (final occurrence in limitedOccurrences) {
        // Note: In a real implementation, you'd need to get the Check object
        // This is simplified for the example
        final checkId = occurrence.checkId;
        final scheduledTime = TimeService.instance.toLocal(occurrence.scheduledTime);
        
        // You would retrieve the check from storage here
        // For now, we'll create a simple notification
        await _scheduleBasicNotification(
          id: occurrence.id,
          checkId: checkId,
          scheduledTime: scheduledTime,
        );
      }
    } catch (e) {
      throw NotificationServiceException('Failed to reschedule notifications: $e');
    }
  }

  /// Schedule a basic notification (used when Check object is not available)
  Future<void> _scheduleBasicNotification({
    required String id,
    required String checkId,
    required tz.TZDateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'momentcue_reminders',
      'Health Check Reminders',
      channelDescription: 'Notifications for your health check reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      actions: [
        AndroidNotificationAction('done', 'Done'),
        AndroidNotificationAction('snooze', 'Snooze'),
        AndroidNotificationAction('skip', 'Skip'),
      ],
    );

    const iOSDetails = DarwinNotificationDetails(
      categoryIdentifier: 'momentcue_reminder',
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id.hashCode,
      'Health Check Reminder',
      'Time for your health check!',
      scheduledTime,
      platformChannelSpecifics,
      payload: _buildNotificationPayload(checkId, id),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  List<AndroidNotificationAction> _buildAndroidActions(SnoozePolicy snoozePolicy) {
    final actions = <AndroidNotificationAction>[
      const AndroidNotificationAction('done', 'Done'),
    ];

    if (snoozePolicy.allowSnooze) {
      actions.add(const AndroidNotificationAction('snooze', 'Snooze'));
    }

    actions.add(const AndroidNotificationAction('skip', 'Skip'));

    return actions;
  }

  String _buildNotificationBody(Check check) {
    final category = _getCategoryDisplayName(check.category);
    if (check.description?.isNotEmpty == true) {
      return check.description!;
    }

    // Generate helpful tips based on category
    switch (check.category) {
      case CheckCategory.hydration:
        return 'Stay hydrated! Time for a glass of water 💧';
      case CheckCategory.posture:
        return 'Take 60 seconds to stretch your neck and shoulders';
      case CheckCategory.screenBreak:
        return 'Give your eyes a break! Look at something 20 feet away for 20 seconds';
      case CheckCategory.breathing:
        return 'Take a moment to breathe deeply and center yourself';
      case CheckCategory.medication:
        return 'Time for your medication reminder';
      case CheckCategory.exercise:
        return 'Time for a quick movement break!';
      default:
        return 'Time for your $category check-in';
    }
  }

  String _getCategoryDisplayName(CheckCategory category) {
    switch (category) {
      case CheckCategory.hydration:
        return 'hydration';
      case CheckCategory.posture:
        return 'posture';
      case CheckCategory.screenBreak:
        return 'screen break';
      case CheckCategory.breathing:
        return 'breathing';
      case CheckCategory.medication:
        return 'medication';
      case CheckCategory.exercise:
        return 'exercise';
      case CheckCategory.custom:
        return 'custom';
    }
  }

  String _buildNotificationPayload(String checkId, String occurrenceId) {
    return '$checkId|$occurrenceId';
  }

  /// Parse notification payload
  static Map<String, String> parsePayload(String payload) {
    final parts = payload.split('|');
    if (parts.length == 2) {
      return {
        'checkId': parts[0],
        'occurrenceId': parts[1],
      };
    }
    return {};
  }

  /// Initialize notification categories for iOS
  Future<void> _initializeNotificationCategories() async {
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.initialize(
            const DarwinInitializationSettings(),
          );
    }
  }

  void dispose() {
    _isInitialized = false;
    _onNotificationTap = null;
    _onNotificationAction = null;
  }
}

class NotificationServiceException implements Exception {
  final String message;
  NotificationServiceException(this.message);

  @override
  String toString() => 'NotificationServiceException: $message';
}
