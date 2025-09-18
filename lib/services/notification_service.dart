import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/simple_check.dart';
import '../models/notification_schedule.dart';
import '../models/notification_sound.dart';
import 'simple_storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  NotificationSound _selectedSound = NotificationSound.getDefault();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();
    try {
      final String localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
      if (kDebugMode) {
        print('Timezone initialized: $localTimeZone');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set local timezone, defaulting to tz.local. Error: $e');
      }
    }

    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    _isInitialized = true;

    // Initialize background worker once
    try {
      await Workmanager().initialize(_workmanagerDispatcher, isInDebugMode: kDebugMode);
      // Register a more frequent periodic task to ensure notifications are always rescheduled
      await Workmanager().registerPeriodicTask(
        'momentcue-reschedule-task',
        'momentcueReschedule',
        frequency: const Duration(minutes: 15), // More frequent to catch missed notifications
        initialDelay: const Duration(minutes: 1), // Start sooner
        constraints: Constraints(networkType: NetworkType.notRequired),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace, // Always replace to ensure latest
        backoffPolicy: BackoffPolicy.exponential,
      );
    } catch (_) {}
  }

  Future<void> _requestAndroidPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
    
    // Create notification channel for Android 8.0+
    await _createNotificationChannel();
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      // For iOS, we assume permissions are granted if we can initialize
      return true;
    }
    return false;
  }

  NotificationSound getSelectedSound() => _selectedSound;

  Future<void> setSelectedSound(NotificationSound sound) async {
    _selectedSound = sound;
    // Recreate notification channel with new sound settings
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  Future<void> _createNotificationChannel() async {
    if (!Platform.isAndroid) return;

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(
      AndroidNotificationChannel(
        'momentcue_checks',
        'Health Check Reminders',
        description: 'Notifications for your health check reminders',
        importance: Importance.max,
        playSound: _selectedSound.id != 'none',
        enableVibration: true,
        showBadge: true,
        sound: _selectedSound.soundPath != null 
            ? RawResourceAndroidNotificationSound(_selectedSound.soundPath!.replaceAll('sounds/', '').replaceAll('.wav', ''))
            : null,
      ),
    );

    // Create a new alarm-focused channel to ensure sound/vibration after reboot
    await androidImplementation?.createNotificationChannel(
      AndroidNotificationChannel(
        'momentcue_checks_alarms',
        'Health Check Alarms',
        description: 'Alarm-style reminders for your health checks',
        importance: Importance.max,
        playSound: _selectedSound.id != 'none',
        enableVibration: true,
        showBadge: true,
        sound: _selectedSound.soundPath != null 
            ? RawResourceAndroidNotificationSound(_selectedSound.soundPath!.replaceAll('sounds/', '').replaceAll('.wav', ''))
            : null,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  Future<void> scheduleCheckNotifications(SimpleCheck check) async {
    if (!_isInitialized) await initialize();
    if (!check.notificationsEnabled || check.notificationSchedules.isEmpty) {
      if (kDebugMode) {
        print('Notifications not enabled or no schedules for check: ${check.title}');
      }
      return;
    }

    if (kDebugMode) {
      print('Scheduling notifications for check: ${check.title}');
      print('Number of schedules: ${check.notificationSchedules.length}');
    }

    // Cancel existing notifications for this check
    await cancelCheckNotifications(check.id);

    for (final schedule in check.notificationSchedules) {
      if (!schedule.isEnabled) continue;

      if (kDebugMode) {
        print('Scheduling notification for schedule: ${schedule.scheduleType}');
      }
      // Use reliable scheduling method that matches working test notification
      await scheduleReliableNotification(check, schedule);
    }
  }

  void _scheduleDartTimerFallback({
    required int secondsFromNow,
    required int notificationId,
    required String title,
    required String body,
    required NotificationDetails details,
    required String payload,
  }) {
    if (secondsFromNow <= 0) return;
    // Use a short-lived Dart timer as a last-resort fallback when the app is alive
    // This does NOT replace OS alarms; it only increases reliability for near-term events
    Future.delayed(Duration(seconds: secondsFromNow), () async {
      try {
        await _notifications.show(
          notificationId,
          title,
          body,
          details,
          payload: payload,
        );
        if (kDebugMode) {
          print('⏱️ Fallback timer fired: notification shown for id=$notificationId');
        }
      } catch (_) {}
    });
  }

  Future<void> scheduleTestNotification() async {
    if (!_isInitialized) await initialize();

    if (kDebugMode) {
      print('Scheduling test notification...');
    }

    final androidDetails = AndroidNotificationDetails(
      'momentcue_checks',
      'Health Check Reminders',
      channelDescription: 'Notifications for your health check reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: _selectedSound.id != 'none',
      fullScreenIntent: false,
      sound: _selectedSound.soundPath != null 
          ? RawResourceAndroidNotificationSound(_selectedSound.soundPath!.replaceAll('sounds/', '').replaceAll('.wav', ''))
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule a test notification for 5 seconds from now
    final now = tz.TZDateTime.now(tz.local);
    final testTime = now.add(const Duration(seconds: 5));

    if (kDebugMode) {
      print('Current time: $now');
      print('Test notification time: $testTime');
    }

    try {
      await _notifications.zonedSchedule(
        999999,
        'MomentCue Test',
        'This is a test notification!',
        testTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'test_notification',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ zonedSchedule failed for test notification: $e');
        print('➡️ Falling back to schedule() with local DateTime');
      }
      final fallbackTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      await _notifications.zonedSchedule(
        999999,
        'MomentCue Test',
        'This is a test notification!',
        fallbackTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'test_notification',
      );
    }

    if (kDebugMode) {
      print('Test notification scheduled successfully');
    }
  }

  // Debug method to create a simple check-like notification
  Future<void> scheduleDebugCheckNotification() async {
    if (!_isInitialized) await initialize();

    if (kDebugMode) {
      print('🔬 SCHEDULING DEBUG CHECK NOTIFICATION...');
    }

    // Create exactly the same notification as test, but for 1 minute
    final androidDetails = AndroidNotificationDetails(
      'momentcue_checks',
      'Health Check Reminders',
      channelDescription: 'Notifications for your health check reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: _selectedSound.id != 'none',
      fullScreenIntent: false,
      sound: _selectedSound.soundPath != null 
          ? RawResourceAndroidNotificationSound(_selectedSound.soundPath!.replaceAll('sounds/', '').replaceAll('.wav', ''))
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    final debugTime = now.add(const Duration(minutes: 1));

    if (kDebugMode) {
      print('🔬 Current time: $now');
      print('🔬 Debug notification time: $debugTime');
    }

    try {
      await _notifications.zonedSchedule(
        888887, // avoid clashing with immediate test (888888)
        'DEBUG Check',
        'This is a debug check notification!',
        debugTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'debug_check',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ zonedSchedule failed for debug check: $e');
        print('➡️ Falling back to schedule() with local DateTime');
      }
      final fallbackTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
      await _notifications.zonedSchedule(
        888887,
        'DEBUG Check',
        'This is a debug check notification!',
        fallbackTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'debug_check',
      );
    }

    if (kDebugMode) {
      print('🔬 Debug check notification scheduled successfully');
    }
  }

  Future<void> listPendingNotifications() async {
    if (!_isInitialized) await initialize();
    
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    
    if (kDebugMode) {
      print('📋 === PENDING NOTIFICATIONS LIST ===');
      print('📋 Total pending: ${pendingNotifications.length}');
      
      for (final notification in pendingNotifications) {
        print('📋 ID: ${notification.id}');
        print('📋 Title: ${notification.title}');
        print('📋 Body: ${notification.body}');
        print('📋 Payload: ${notification.payload}');
        print('📋 ---');
      }
      print('📋 === END PENDING NOTIFICATIONS ===');
    }
  }

  Future<void> checkExactAlarmPermission() async {
    if (!_isInitialized) await initialize();
    
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (kDebugMode) {
        print('🔐 === EXACT ALARM PERMISSION CHECK ===');
      }

      try {
        final bool? notificationsEnabled = await androidImplementation?.areNotificationsEnabled();
        
        if (kDebugMode) {
          print('🔐 Notifications enabled: $notificationsEnabled');
        }

        // Try to check exact alarm permission
        try {
          final bool? canSchedule = await androidImplementation?.canScheduleExactNotifications();
          if (kDebugMode) {
            print('🔐 Can schedule exact notifications: $canSchedule');
          }
          
          if (canSchedule == false) {
            if (kDebugMode) {
              print('❌ EXACT ALARM PERMISSION DENIED - This is why notifications don\'t fire!');
              print('📱 Go to Settings > Apps > MomentCue > Alarms & reminders to enable');
            }
          } else if (canSchedule == true) {
            if (kDebugMode) {
              print('✅ Exact alarm permission granted');
            }
          } else {
            if (kDebugMode) {
              print('⚠️ Exact alarm permission status unknown (older Android version?)');
            }
          }
        } catch (exactAlarmError) {
          if (kDebugMode) {
            print('⚠️ canScheduleExactNotifications not available: $exactAlarmError');
            print('📱 This might be Android < 12 or method not supported');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error checking permissions: $e');
        }
      }
      
      if (kDebugMode) {
        print('🔐 === END PERMISSION CHECK ===');
      }
    }
  }

  // Add method that works exactly like test notification but for future time
  Future<void> scheduleReliableNotification(SimpleCheck check, NotificationSchedule schedule) async {
    final notificationId = _generateNotificationId(check.id, schedule.id);
    final nextOccurrence = _calculateNextOccurrence(schedule);
    if (nextOccurrence == null) return;

    final now = tz.TZDateTime.now(tz.local);
    final secondsFromNow = nextOccurrence.difference(now).inSeconds;

    if (kDebugMode) {
      print('🚀 === RELIABLE NOTIFICATION SCHEDULING ===');
      print('🚀 Check: ${check.title}');
      print('🚀 Seconds from now: $secondsFromNow');
      print('🚀 Target time: $nextOccurrence');
    }

    if (secondsFromNow <= 0) {
      if (kDebugMode) {
        print('❌ Cannot schedule in the past');
      }
      return;
    }

    // Use EXACTLY the same approach as working test notification
    final testTime = now.add(Duration(seconds: secondsFromNow));
    
    final androidDetails = AndroidNotificationDetails(
      'momentcue_checks_alarms',
      'Health Check Alarms',
      channelDescription: 'Alarm-style reminders for your health checks',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: _selectedSound.id != 'none',
      fullScreenIntent: false,
      sound: _selectedSound.soundPath != null 
          ? RawResourceAndroidNotificationSound(_selectedSound.soundPath!.replaceAll('sounds/', '').replaceAll('.wav', ''))
          : null,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250, 500, 250]),
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use alarm clock or exact while idle for reliable wake-up when app is closed
    try {
      AndroidScheduleMode selectedMode = AndroidScheduleMode.alarmClock;
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImpl =
            _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        try {
          final bool? canExact = await androidImpl?.canScheduleExactNotifications();
          if (kDebugMode) {
            print('🔐 Exact alarm capability: $canExact');
          }
          if (canExact == true) {
            selectedMode = AndroidScheduleMode.exactAllowWhileIdle;
          } else {
            // Try to request permission once; if still false, stick with alarmClock
            await androidImpl?.requestExactAlarmsPermission();
            final bool? recheck = await androidImpl?.canScheduleExactNotifications();
            if (recheck == true) {
              selectedMode = AndroidScheduleMode.exactAllowWhileIdle;
            } else {
              selectedMode = AndroidScheduleMode.alarmClock;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Exact alarm capability check failed: $e');
          }
          selectedMode = AndroidScheduleMode.alarmClock;
        }
      }

      await _notifications.zonedSchedule(
        notificationId,
        check.title,
        check.description ?? 'Time for your health check!',
        testTime,
        notificationDetails,
        androidScheduleMode: selectedMode,
        payload: 'check_${check.id}_schedule_${schedule.id}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ zonedSchedule failed for reliable schedule: $e');
        print('➡️ Falling back to inexact schedule as last resort');
      }
      try {
        await _notifications.zonedSchedule(
          notificationId,
          check.title,
          check.description ?? 'Time for your health check!',
          testTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexact,
          payload: 'check_${check.id}_schedule_${schedule.id}',
        );
      } catch (_) {}
    }

    // Add a near-term Dart timer fallback while app is alive
    _scheduleDartTimerFallback(
      secondsFromNow: secondsFromNow,
      notificationId: notificationId,
      title: check.title,
      body: check.description ?? 'Time for your health check!',
      details: notificationDetails,
      payload: 'check_${check.id}_schedule_${schedule.id}',
    );

    if (kDebugMode) {
      print('🚀 Reliable notification scheduled successfully');
      print('🚀 === END RELIABLE SCHEDULING ===');
    }
  }

  // Add a method to use inexact scheduling as fallback
  Future<void> scheduleInexactNotification(SimpleCheck check, NotificationSchedule schedule) async {
    final notificationId = _generateNotificationId(check.id, schedule.id);

    if (kDebugMode) {
      print('🔄 === SCHEDULING INEXACT NOTIFICATION (FALLBACK) ===');
      print('🔄 Check: ${check.title}');
      print('🔄 ID: $notificationId');
    }

    // Use the same notification details
    final androidDetails = AndroidNotificationDetails(
      'momentcue_checks',
      'Health Check Reminders',
      channelDescription: 'Notifications for your health check reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: _selectedSound.id != 'none',
      fullScreenIntent: false,
      sound: _selectedSound.soundPath != null 
          ? RawResourceAndroidNotificationSound(_selectedSound.soundPath!.replaceAll('sounds/', '').replaceAll('.wav', ''))
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final nextOccurrence = _calculateNextOccurrence(schedule);
    if (nextOccurrence == null) return;

    try {
      // Use inexact scheduling (no exactAllowWhileIdle)
      await _notifications.zonedSchedule(
        notificationId,
        check.title,
        check.description ?? 'Time for your health check!',
        nextOccurrence,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        payload: 'check_${check.id}_schedule_${schedule.id}',
      );

      if (kDebugMode) {
        print('🔄 Inexact notification scheduled successfully');
        print('🔄 === END INEXACT SCHEDULING ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling inexact notification: $e');
      }
    }
  }

  Future<void> showImmediateNotification() async {
    if (!_isInitialized) await initialize();

    if (kDebugMode) {
      print('Showing immediate notification...');
    }

    final androidDetails = AndroidNotificationDetails(
      'momentcue_checks',
      'Health Check Reminders',
      channelDescription: 'Notifications for your health check reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: _selectedSound.id != 'none',
      fullScreenIntent: true,
      sound: _selectedSound.soundPath != null 
          ? RawResourceAndroidNotificationSound(_selectedSound.soundPath!.replaceAll('sounds/', '').replaceAll('.wav', ''))
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      888888,
      'MomentCue Immediate Test',
      'This is an immediate test notification!',
      notificationDetails,
      payload: 'immediate_test',
    );

    if (kDebugMode) {
      print('Immediate notification shown successfully');
    }
  }

  Future<void> _scheduleNotification(SimpleCheck check, NotificationSchedule schedule) async {
    final notificationId = _generateNotificationId(check.id, schedule.id);

    if (kDebugMode) {
      print('=== SCHEDULING NOTIFICATION DEBUG ===');
      print('Check ID: ${check.id}');
      print('Schedule ID: ${schedule.id}');
      print('Notification ID: $notificationId');
      print('Schedule Type: ${schedule.scheduleType}');
      print('Schedule Data: ${schedule.scheduleData}');
      print('Is Enabled: ${schedule.isEnabled}');
    }

    // Use exact same notification details as working immediate notification
    final androidDetails = AndroidNotificationDetails(
      'momentcue_checks',
      'Health Check Reminders',
      channelDescription: 'Notifications for your health check reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: _selectedSound.id != 'none',
      fullScreenIntent: true,
      sound: _selectedSound.soundPath != null 
          ? RawResourceAndroidNotificationSound(_selectedSound.soundPath!.replaceAll('sounds/', '').replaceAll('.wav', ''))
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Calculate next occurrence based on schedule type
    final nextOccurrence = _calculateNextOccurrence(schedule);
    if (nextOccurrence == null) {
      if (kDebugMode) {
        print('ERROR: No next occurrence calculated for schedule: ${schedule.scheduleType}');
        print('Schedule data was: ${schedule.scheduleData}');
      }
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    if (kDebugMode) {
      print('Current time: $now');
      print('Next occurrence: $nextOccurrence');
      print('Time difference: ${nextOccurrence.difference(now)}');
      print('Is in future: ${nextOccurrence.isAfter(now)}');
    }

    try {
    // Try the working method from test notification - simple scheduling
    final minutesFromNow = nextOccurrence.difference(now).inMinutes;
    
    if (kDebugMode) {
      print('🔧 Using simple schedule method - $minutesFromNow minutes from now');
    }
    
    if (minutesFromNow <= 0) {
      if (kDebugMode) {
        print('❌ Cannot schedule notification in the past');
      }
      return;
    }
    
    // Use simple schedule like the working test notification
    try {
      await _notifications.zonedSchedule(
        notificationId,
        check.title,
        check.description ?? 'Time for your health check!',
        nextOccurrence,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'check_${check.id}_schedule_${schedule.id}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ zonedSchedule failed in _scheduleNotification: $e');
        print('➡️ Falling back to schedule() with local DateTime');
      }
      final fallbackTime = tz.TZDateTime.now(tz.local).add(nextOccurrence.difference(now));
      await _notifications.zonedSchedule(
        notificationId,
        check.title,
        check.description ?? 'Time for your health check!',
        fallbackTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: 'check_${check.id}_schedule_${schedule.id}',
      );
    }

    // Timer fallback while app alive
    _scheduleDartTimerFallback(
      secondsFromNow: nextOccurrence.difference(now).inSeconds,
      notificationId: notificationId,
      title: check.title,
      body: check.description ?? 'Time for your health check!',
      details: notificationDetails,
      payload: 'check_${check.id}_schedule_${schedule.id}',
    );

      if (kDebugMode) {
        print('✅ Notification scheduled successfully!');
        print('=== END SCHEDULING DEBUG ===');
      }

      // Verify the notification was actually scheduled
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      final scheduled = pendingNotifications.where((n) => n.id == notificationId).toList();
      
      if (kDebugMode) {
        print('📋 Pending notifications count: ${pendingNotifications.length}');
        print('📋 This notification in pending list: ${scheduled.isNotEmpty}');
        if (scheduled.isNotEmpty) {
          print('📋 Scheduled notification: ${scheduled.first.title} at ${scheduled.first.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR scheduling notification: $e');
        print('=== END SCHEDULING DEBUG ===');
      }
      rethrow;
    }
  }

  int _generateNotificationId(String checkId, String scheduleId) {
    // Create a unique ID based on check and schedule IDs
    return (checkId.hashCode + scheduleId.hashCode).abs() % 2147483647;
  }

  List<AndroidNotificationAction> _getNotificationActions(SimpleCheck check) {
    final actions = <AndroidNotificationAction>[];

    // Always add Done action
    actions.add(const AndroidNotificationAction(
      'done',
      'Done',
      icon: DrawableResourceAndroidBitmap('@drawable/ic_done'),
      showsUserInterface: true,
    ));

    // Add Snooze action if allowed
    if (check.allowSnooze) {
      actions.add(const AndroidNotificationAction(
        'snooze',
        'Snooze',
        icon: DrawableResourceAndroidBitmap('@drawable/ic_snooze'),
        showsUserInterface: true,
      ));
    }

    // Add Skip action
    actions.add(const AndroidNotificationAction(
      'skip',
      'Skip',
      icon: DrawableResourceAndroidBitmap('@drawable/ic_skip'),
      showsUserInterface: true,
    ));

    return actions;
  }

  tz.TZDateTime? _calculateNextOccurrence(NotificationSchedule schedule) {
    final now = tz.TZDateTime.now(tz.local);

    switch (schedule.scheduleType) {
      case ScheduleType.interval:
        return _calculateIntervalOccurrence(schedule, now);
      case ScheduleType.daily:
        return _calculateDailyOccurrence(schedule, now);
      case ScheduleType.weekly:
        return _calculateWeeklyOccurrence(schedule, now);
      case ScheduleType.monthly:
        return _calculateMonthlyOccurrence(schedule, now);
      case ScheduleType.yearly:
        return _calculateYearlyOccurrence(schedule, now);
      case ScheduleType.weekday:
        return _calculateWeekdayOccurrence(schedule, now);
      case ScheduleType.weekend:
        return _calculateWeekendOccurrence(schedule, now);
      case ScheduleType.custom:
        return _calculateCustomOccurrence(schedule, now);
    }
  }

  tz.TZDateTime? _calculateIntervalOccurrence(NotificationSchedule schedule, tz.TZDateTime now) {
    final interval = schedule.scheduleData['interval'] as int? ?? 1;
    final unit = TimeUnit.values[schedule.scheduleData['unit'] as int? ?? 0];

    switch (unit) {
      case TimeUnit.minutes:
        return now.add(Duration(minutes: interval));
      case TimeUnit.hours:
        return now.add(Duration(hours: interval));
      case TimeUnit.days:
        return now.add(Duration(days: interval));
      case TimeUnit.weeks:
        return now.add(Duration(days: interval * 7));
      case TimeUnit.months:
        return tz.TZDateTime(now.location, now.year, now.month + interval, now.day, now.hour, now.minute);
      case TimeUnit.years:
        return tz.TZDateTime(now.location, now.year + interval, now.month, now.day, now.hour, now.minute);
    }
  }

  tz.TZDateTime? _calculateDailyOccurrence(NotificationSchedule schedule, tz.TZDateTime now) {
    final times = (schedule.scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    if (kDebugMode) {
      print('🕐 DAILY OCCURRENCE CALCULATION');
      print('Times in schedule: $times');
      print('Current time: $now');
    }
    
    if (times.isEmpty) {
      if (kDebugMode) {
        print('❌ No times found in schedule data');
      }
      return null;
    }

    // Find the next occurrence today or tomorrow
    for (final time in times) {
      final hour = time['hour'] as int;
      final minute = time['minute'] as int;
      final today = tz.TZDateTime(now.location, now.year, now.month, now.day, hour, minute);
      
      if (kDebugMode) {
        print('Checking time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} -> $today');
        print('Is after now? ${today.isAfter(now)}');
      }
      
      if (today.isAfter(now)) {
        if (kDebugMode) {
          print('✅ Selected time for today: $today');
        }
        return today;
      }
    }

    // If no time today, use first time tomorrow
    if (times.isNotEmpty) {
      final firstTime = times.first;
      final hour = firstTime['hour'] as int;
      final minute = firstTime['minute'] as int;
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTime = tz.TZDateTime(tomorrow.location, tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
      
      if (kDebugMode) {
        print('No time today, using tomorrow: $tomorrowTime');
      }
      
      return tomorrowTime;
    }

    return null;
  }

  tz.TZDateTime? _calculateWeeklyOccurrence(NotificationSchedule schedule, tz.TZDateTime now) {
    final days = (schedule.scheduleData['days'] as List<dynamic>?)?.cast<int>() ?? [];
    final times = (schedule.scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    if (days.isEmpty || times.isEmpty) return null;

    // Find next occurrence within the next 7 days
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final weekday = targetDate.weekday;
      
      if (days.contains(weekday)) {
        for (final time in times) {
          final hour = time['hour'] as int;
          final minute = time['minute'] as int;
          final occurrence = tz.TZDateTime(targetDate.location, targetDate.year, targetDate.month, targetDate.day, hour, minute);
          
          if (occurrence.isAfter(now)) {
            return occurrence;
          }
        }
      }
    }

    return null;
  }

  tz.TZDateTime? _calculateMonthlyOccurrence(NotificationSchedule schedule, tz.TZDateTime now) {
    final dayOfMonth = schedule.scheduleData['dayOfMonth'] as int?;
    final weekOfMonth = schedule.scheduleData['weekOfMonth'] as int?;
    final dayOfWeek = schedule.scheduleData['dayOfWeek'] as int?;
    final times = (schedule.scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    if (times.isEmpty) return null;

    // Calculate target day of month
    int targetDay;
    if (dayOfMonth != null) {
      targetDay = dayOfMonth;
    } else if (weekOfMonth != null && dayOfWeek != null) {
      // Calculate the Nth weekday of the month
      targetDay = _calculateNthWeekdayOfMonth(now.year, now.month, weekOfMonth, dayOfWeek);
    } else {
      targetDay = 1;
    }

    // Find next occurrence
    for (int monthOffset = 0; monthOffset < 12; monthOffset++) {
      final targetDate = tz.TZDateTime(now.location, now.year, now.month + monthOffset, 1);
      final daysInMonth = DateTime(targetDate.year, targetDate.month + 1, 0).day;
      final actualDay = targetDay > daysInMonth ? daysInMonth : targetDay;
      
      final occurrenceDate = tz.TZDateTime(targetDate.location, targetDate.year, targetDate.month, actualDay);
      
      if (occurrenceDate.isAfter(now)) {
        for (final time in times) {
          final hour = time['hour'] as int;
          final minute = time['minute'] as int;
          final occurrence = tz.TZDateTime(occurrenceDate.location, occurrenceDate.year, occurrenceDate.month, occurrenceDate.day, hour, minute);
          
          if (occurrence.isAfter(now)) {
            return occurrence;
          }
        }
      }
    }

    return null;
  }

  tz.TZDateTime? _calculateYearlyOccurrence(NotificationSchedule schedule, tz.TZDateTime now) {
    final month = schedule.scheduleData['month'] as int? ?? 1;
    final dayOfMonth = schedule.scheduleData['dayOfMonth'] as int? ?? 1;
    final times = (schedule.scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    
    if (times.isEmpty) return null;

    // Find next occurrence within the next 2 years
    for (int yearOffset = 0; yearOffset < 2; yearOffset++) {
      final targetYear = now.year + yearOffset;
      final targetMonth = yearOffset == 0 && month < now.month ? month + 12 : month;
      final targetDate = tz.TZDateTime(now.location, targetYear, targetMonth, 1);
      
      final daysInMonth = DateTime(targetDate.year, targetDate.month + 1, 0).day;
      final actualDay = dayOfMonth > daysInMonth ? daysInMonth : dayOfMonth;
      
      final occurrenceDate = tz.TZDateTime(targetDate.location, targetDate.year, targetDate.month, actualDay);
      
      if (occurrenceDate.isAfter(now)) {
        for (final time in times) {
          final hour = time['hour'] as int;
          final minute = time['minute'] as int;
          final occurrence = tz.TZDateTime(occurrenceDate.location, occurrenceDate.year, occurrenceDate.month, occurrenceDate.day, hour, minute);
          
          if (occurrence.isAfter(now)) {
            return occurrence;
          }
        }
      }
    }

    return null;
  }

  tz.TZDateTime? _calculateWeekdayOccurrence(NotificationSchedule schedule, tz.TZDateTime now) {
    final times = (schedule.scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (times.isEmpty) return null;

    // Find next weekday occurrence
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final weekday = targetDate.weekday;
      
      if (weekday >= 1 && weekday <= 5) { // Monday to Friday
        for (final time in times) {
          final hour = time['hour'] as int;
          final minute = time['minute'] as int;
          final occurrence = tz.TZDateTime(targetDate.location, targetDate.year, targetDate.month, targetDate.day, hour, minute);
          
          if (occurrence.isAfter(now)) {
            return occurrence;
          }
        }
      }
    }

    return null;
  }

  tz.TZDateTime? _calculateWeekendOccurrence(NotificationSchedule schedule, tz.TZDateTime now) {
    final times = (schedule.scheduleData['times'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (times.isEmpty) return null;

    // Find next weekend occurrence
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final weekday = targetDate.weekday;
      
      if (weekday == 6 || weekday == 7) { // Saturday or Sunday
        for (final time in times) {
          final hour = time['hour'] as int;
          final minute = time['minute'] as int;
          final occurrence = tz.TZDateTime(targetDate.location, targetDate.year, targetDate.month, targetDate.day, hour, minute);
          
          if (occurrence.isAfter(now)) {
            return occurrence;
          }
        }
      }
    }

    return null;
  }

  tz.TZDateTime? _calculateCustomOccurrence(NotificationSchedule schedule, tz.TZDateTime now) {
    // For custom schedules, we'll implement basic patterns
    // This could be extended to support RRULE parsing
    return now.add(const Duration(hours: 1)); // Default to 1 hour from now
  }

  int _calculateNthWeekdayOfMonth(int year, int month, int weekOfMonth, int dayOfWeek) {
    final firstDayOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysToAdd = (dayOfWeek - firstWeekday + 7) % 7;
    final firstOccurrence = firstDayOfMonth.add(Duration(days: daysToAdd));
    final nthOccurrence = firstOccurrence.add(Duration(days: (weekOfMonth - 1) * 7));
    
    // Check if the nth occurrence is still in the same month
    if (nthOccurrence.month == month) {
      return nthOccurrence.day;
    } else {
      // Return the last occurrence of the weekday in the month
      final lastDayOfMonth = DateTime(year, month + 1, 0);
      final lastWeekday = lastDayOfMonth.weekday;
      final daysToSubtract = (lastWeekday - dayOfWeek + 7) % 7;
      return lastDayOfMonth.subtract(Duration(days: daysToSubtract)).day;
    }
  }

  DateTimeComponents? _getDateTimeComponents(ScheduleType scheduleType) {
    switch (scheduleType) {
      case ScheduleType.daily:
        return DateTimeComponents.time;
      case ScheduleType.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case ScheduleType.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case ScheduleType.yearly:
        return DateTimeComponents.dateAndTime;
      case ScheduleType.weekday:
      case ScheduleType.weekend:
        return DateTimeComponents.dayOfWeekAndTime;
      case ScheduleType.interval:
      case ScheduleType.custom:
        return null; // No repeating; will be re-scheduled manually after firing
    }
  }

  Future<void> cancelCheckNotifications(String checkId) async {
    if (!_isInitialized) await initialize();

    // Get all pending notifications
    final pendingNotifications = await _notifications.pendingNotificationRequests();

    // Cancel only notifications for this check by inspecting the payload
    for (final notification in pendingNotifications) {
      final payload = notification.payload ?? '';
      if (payload.startsWith('check_${checkId}_')) {
        await _notifications.cancel(notification.id);
      }
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();
    await _notifications.cancelAll();
  }

  void _onNotificationTapped(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (kDebugMode) {
      print('Notification tapped: actionId=$actionId, payload=$payload');
    }

    // Handle different actions
    switch (actionId) {
      case 'done':
        _handleDoneAction(payload);
        break;
      case 'snooze':
        _handleSnoozeAction(payload);
        break;
      case 'skip':
        _handleSkipAction(payload);
        break;
      default:
        _handleDefaultAction(payload);
        break;
    }
  }

  void _handleDoneAction(String? payload) {
    // Mark check as completed
    if (kDebugMode) {
      print('Check marked as done: $payload');
    }
    // TODO: Update check completion status in storage
  }

  void _handleSnoozeAction(String? payload) {
    // Snooze the notification for 15 minutes
    if (kDebugMode) {
      print('Check snoozed: $payload');
    }
    // TODO: Implement snooze logic
  }

  void _handleSkipAction(String? payload) {
    // Skip this occurrence
    if (kDebugMode) {
      print('Check skipped: $payload');
    }
    // TODO: Update check skip status
  }

  void _handleDefaultAction(String? payload) {
    // Open the app or show check details
    if (kDebugMode) {
      print('Notification opened: $payload');
    }
    // TODO: Navigate to check details
  }
}

// Workmanager entry point
@pragma('vm:entry-point')
void _workmanagerDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Ensure timezone db is ready
      tz.initializeTimeZones();
      // Recreate scheduled notifications for enabled checks
      final checks = await SimpleStorageService.instance.getChecks();
      final service = NotificationService();
      await service.initialize();
      for (final check in checks) {
        if (check.notificationsEnabled && check.enabled && check.notificationSchedules.isNotEmpty) {
          await service.scheduleCheckNotifications(check);
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Workmanager reschedule error: $e');
      }
      return false;
    }
  });
}
