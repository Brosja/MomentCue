import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/time_service.dart';
import 'services/schedule_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'utils/app_theme.dart';
import 'generated/l10n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  // Initialize services
  final storageService = StorageService();
  await storageService.initialize();
  
  final timeService = TimeService();
  await timeService.initialize();
  
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  final scheduleService = ScheduleService();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(MomentCueApp(
    storageService: storageService,
    notificationService: notificationService,
    timeService: timeService,
    scheduleService: scheduleService,
  ));
}

class MomentCueApp extends StatelessWidget {
  final StorageService storageService;
  final NotificationService notificationService;
  final TimeService timeService;
  final ScheduleService scheduleService;

  const MomentCueApp({
    super.key,
    required this.storageService,
    required this.notificationService,
    required this.timeService,
    required this.scheduleService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<NotificationService>.value(value: notificationService),
        Provider<TimeService>.value(value: timeService),
        Provider<ScheduleService>.value(value: scheduleService),
      ],
      child: MaterialApp(
        title: 'MomentCue',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: FutureBuilder<bool>(
          future: storageService.isFirstLaunch(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            
            final isFirstLaunch = snapshot.data ?? true;
            if (isFirstLaunch) {
              return const OnboardingScreen();
            } else {
              return const HomeScreen();
            }
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.health_and_safety,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'MomentCue',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Preparing your wellness companion...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
