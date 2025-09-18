import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _onboardingVersionKey = 'onboarding_version';
  static const String _currentOnboardingVersion = '1.0';
  
  /// Check if onboarding has been completed
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool(_onboardingCompletedKey) ?? false;
      final version = prefs.getString(_onboardingVersionKey) ?? '';
      
      // If version changed, reset onboarding
      if (version != _currentOnboardingVersion) {
        await _resetOnboarding();
        return false;
      }
      
      return completed;
    } catch (e) {
      return false;
    }
  }
  
  /// Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      await prefs.setString(_onboardingVersionKey, _currentOnboardingVersion);
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Reset onboarding (for testing or version updates)
  static Future<void> _resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompletedKey);
      await prefs.remove(_onboardingVersionKey);
    } catch (e) {
      // Handle error silently
    }
  }
  
  /// Reset onboarding (public method for settings)
  static Future<void> resetOnboarding() async {
    await _resetOnboarding();
  }
}
