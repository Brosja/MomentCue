import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:momentcue/main.dart';
import 'package:momentcue/services/storage_service.dart';
import 'package:momentcue/services/notification_service.dart';
import 'package:momentcue/services/time_service.dart';
import 'package:momentcue/services/schedule_service.dart';

void main() {
  group('MomentCue App Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Create mock services
      final storageService = StorageService();
      final notificationService = NotificationService();
      final timeService = TimeService();
      final scheduleService = ScheduleService();

      // Build our app and trigger a frame
      await tester.pumpWidget(
        MomentCueApp(
          storageService: storageService,
          notificationService: notificationService,
          timeService: timeService,
          scheduleService: scheduleService,
        ),
      );

      // Verify that the app builds
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Loading screen should display', (WidgetTester tester) async {
      // Create mock services
      final storageService = StorageService();
      final notificationService = NotificationService();
      final timeService = TimeService();
      final scheduleService = ScheduleService();

      await tester.pumpWidget(
        MomentCueApp(
          storageService: storageService,
          notificationService: notificationService,
          timeService: timeService,
          scheduleService: scheduleService,
        ),
      );

      // Should show loading screen initially
      expect(find.text('MomentCue'), findsWidgets);
    });
  });
}
