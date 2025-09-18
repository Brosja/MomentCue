import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/simple_check.dart';

class SimpleStorageService {
  static const String _checksKey = 'momentcue_checks';
  
  static SimpleStorageService? _instance;
  static SimpleStorageService get instance => _instance ??= SimpleStorageService._();
  
  SimpleStorageService._();
  
  Future<List<SimpleCheck>> getChecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checksJson = prefs.getStringList(_checksKey) ?? [];
      
      return checksJson.map((jsonString) {
        final json = jsonDecode(jsonString);
        return SimpleCheck.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error loading checks: $e');
      return [];
    }
  }
  
  Future<void> saveChecks(List<SimpleCheck> checks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checksJson = checks.map((check) => jsonEncode(check.toJson())).toList();
      await prefs.setStringList(_checksKey, checksJson);
    } catch (e) {
      print('Error saving checks: $e');
    }
  }
  
  Future<void> addCheck(SimpleCheck check) async {
    final checks = await getChecks();
    checks.add(check);
    await saveChecks(checks);
  }
  
  Future<void> updateCheck(SimpleCheck updatedCheck) async {
    final checks = await getChecks();
    final index = checks.indexWhere((check) => check.id == updatedCheck.id);
    if (index != -1) {
      checks[index] = updatedCheck;
      await saveChecks(checks);
    }
  }
  
  Future<void> deleteCheck(String checkId) async {
    final checks = await getChecks();
    checks.removeWhere((check) => check.id == checkId);
    await saveChecks(checks);
  }
  
  Future<void> clearAllChecks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checksKey);
  }
}
