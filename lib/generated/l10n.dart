// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of(context, S);
  }

  // App strings
  String get appTitle => 'MomentCue';
  String get welcomeTitle => 'Welcome to MomentCue';
  String get welcomeSubtitle => 'Your privacy-first wellness companion for micro-health check-ins';
  
  // Navigation
  String get navToday => 'Today';
  String get navChecks => 'Checks';
  String get navAnalytics => 'Analytics';
  String get navSettings => 'Settings';
  
  // Common
  String get save => 'Save';
  String get cancel => 'Cancel';
  String get delete => 'Delete';
  String get edit => 'Edit';
  String get done => 'Done';
  String get skip => 'Skip';
  String get snooze => 'Snooze';
  String get loading => 'Loading...';
  String get error => 'Error';
  
  // Onboarding
  String get getStarted => 'Get Started';
  String get allowNotifications => 'Allow Notifications';
  String get skipForNow => 'Skip for now';
  String get createChecks => 'Create checks';
  String get startYourJourney => 'Start Your Journey';
  
  // Categories
  String get categoryHydration => 'Hydration';
  String get categoryPosture => 'Posture';
  String get categoryMedication => 'Medication';
  String get categoryScreenBreak => 'Screen Break';
  String get categoryBreathing => 'Breathing';
  String get categoryExercise => 'Exercise';
  String get categoryCustom => 'Custom';
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'es'),
      Locale.fromSubtags(languageCode: 'de'),
      Locale.fromSubtags(languageCode: 'fr'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}

Future<bool> initializeMessages(String localeName) async {
  // In a real app, this would load actual translation files
  // For now, we'll just return true as we're using hardcoded English strings
  return Future.value(true);
}
