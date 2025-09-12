import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/check.dart';
import '../models/schedule.dart';

class StorageService {
  static const String _checksBoxName = 'checks';
  static const String _schedulesBoxName = 'schedules';
  static const String _occurrencesBoxName = 'occurrences';
  static const String _settingsBoxName = 'settings';
  static const String _encryptionKeyName = 'hive_encryption_key';
  
  late Box<Check> _checksBox;
  late Box<Schedule> _schedulesBox;
  late Box<ScheduleOccurrence> _occurrencesBox;
  late Box _settingsBox;
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  bool _isInitialized = false;
  List<int>? _encryptionKey;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register adapters
      _registerAdapters();
      
      // Get or generate encryption key
      _encryptionKey = await _getOrCreateEncryptionKey();
      
      // Open encrypted boxes
      _checksBox = await Hive.openBox<Check>(
        _checksBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
      
      _schedulesBox = await Hive.openBox<Schedule>(
        _schedulesBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
      
      _occurrencesBox = await Hive.openBox<ScheduleOccurrence>(
        _occurrencesBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
      
      _settingsBox = await Hive.openBox(
        _settingsBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
      
      _isInitialized = true;
    } catch (e) {
      throw StorageException('Failed to initialize storage: $e');
    }
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CheckAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CheckCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ScheduleTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SnoozePolicyAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(CheckAnalyticsAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ScheduleAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      // Already registered in check.dart
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(SequenceIntervalAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(TimeUnitAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ScheduleOccurrenceAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(OccurrenceStatusAdapter());
    }
  }

  Future<List<int>> _getOrCreateEncryptionKey() async {
    try {
      // Try to get existing key
      final existingKey = await _secureStorage.read(key: _encryptionKeyName);
      if (existingKey != null) {
        return base64.decode(existingKey);
      }

      // Generate new key
      final newKey = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64.encode(newKey),
      );
      return newKey;
    } catch (e) {
      throw StorageException('Failed to get or create encryption key: $e');
    }
  }

  Future<void> regenerateEncryptionKey() async {
    if (!_isInitialized) {
      throw StorageException('Storage not initialized');
    }

    try {
      // Export all data first
      final checks = getAllChecks();
      final schedules = getAllSchedules();
      final occurrences = getAllOccurrences();
      final settings = getAllSettings();

      // Close boxes
      await _checksBox.close();
      await _schedulesBox.close();
      await _occurrencesBox.close();
      await _settingsBox.close();

      // Delete old boxes
      await Hive.deleteBoxFromDisk(_checksBoxName);
      await Hive.deleteBoxFromDisk(_schedulesBoxName);
      await Hive.deleteBoxFromDisk(_occurrencesBoxName);
      await Hive.deleteBoxFromDisk(_settingsBoxName);

      // Generate new key
      _encryptionKey = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: base64.encode(_encryptionKey!),
      );

      // Recreate boxes with new key
      _checksBox = await Hive.openBox<Check>(
        _checksBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
      
      _schedulesBox = await Hive.openBox<Schedule>(
        _schedulesBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
      
      _occurrencesBox = await Hive.openBox<ScheduleOccurrence>(
        _occurrencesBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );
      
      _settingsBox = await Hive.openBox(
        _settingsBoxName,
        encryptionCipher: HiveAesCipher(_encryptionKey!),
      );

      // Restore data
      for (final check in checks) {
        await _checksBox.put(check.id, check);
      }
      for (final schedule in schedules) {
        await _schedulesBox.put(schedule.id, schedule);
      }
      for (final occurrence in occurrences) {
        await _occurrencesBox.put(occurrence.id, occurrence);
      }
      for (final entry in settings.entries) {
        await _settingsBox.put(entry.key, entry.value);
      }
    } catch (e) {
      throw StorageException('Failed to regenerate encryption key: $e');
    }
  }

  // Check operations
  Future<void> saveCheck(Check check) async {
    _ensureInitialized();
    try {
      check.updatedAt = DateTime.now();
      await _checksBox.put(check.id, check);
    } catch (e) {
      throw StorageException('Failed to save check: $e');
    }
  }

  Check? getCheck(String id) {
    _ensureInitialized();
    return _checksBox.get(id);
  }

  List<Check> getAllChecks() {
    _ensureInitialized();
    return _checksBox.values.toList();
  }

  List<Check> getActiveChecks() {
    _ensureInitialized();
    return _checksBox.values
        .where((check) => check.enabled && !check.isArchived)
        .toList();
  }

  List<Check> getChecksByCategory(CheckCategory category) {
    _ensureInitialized();
    return _checksBox.values
        .where((check) => check.category == category)
        .toList();
  }

  Future<void> deleteCheck(String id) async {
    _ensureInitialized();
    try {
      await _checksBox.delete(id);
      // Also delete related schedules and occurrences
      await deleteSchedulesByCheckId(id);
      await deleteOccurrencesByCheckId(id);
    } catch (e) {
      throw StorageException('Failed to delete check: $e');
    }
  }

  // Schedule operations
  Future<void> saveSchedule(Schedule schedule) async {
    _ensureInitialized();
    try {
      await _schedulesBox.put(schedule.id, schedule);
    } catch (e) {
      throw StorageException('Failed to save schedule: $e');
    }
  }

  Schedule? getSchedule(String id) {
    _ensureInitialized();
    return _schedulesBox.get(id);
  }

  List<Schedule> getAllSchedules() {
    _ensureInitialized();
    return _schedulesBox.values.toList();
  }

  Future<void> deleteSchedule(String id) async {
    _ensureInitialized();
    try {
      await _schedulesBox.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete schedule: $e');
    }
  }

  Future<void> deleteSchedulesByCheckId(String checkId) async {
    _ensureInitialized();
    try {
      final schedulesToDelete = _schedulesBox.values
          .where((schedule) => schedule.id.startsWith(checkId))
          .toList();
      
      for (final schedule in schedulesToDelete) {
        await _schedulesBox.delete(schedule.id);
      }
    } catch (e) {
      throw StorageException('Failed to delete schedules for check: $e');
    }
  }

  // Occurrence operations
  Future<void> saveOccurrence(ScheduleOccurrence occurrence) async {
    _ensureInitialized();
    try {
      await _occurrencesBox.put(occurrence.id, occurrence);
    } catch (e) {
      throw StorageException('Failed to save occurrence: $e');
    }
  }

  ScheduleOccurrence? getOccurrence(String id) {
    _ensureInitialized();
    return _occurrencesBox.get(id);
  }

  List<ScheduleOccurrence> getAllOccurrences() {
    _ensureInitialized();
    return _occurrencesBox.values.toList();
  }

  List<ScheduleOccurrence> getOccurrencesByCheckId(String checkId) {
    _ensureInitialized();
    return _occurrencesBox.values
        .where((occurrence) => occurrence.checkId == checkId)
        .toList();
  }

  List<ScheduleOccurrence> getOccurrencesInRange(
    DateTime start,
    DateTime end,
  ) {
    _ensureInitialized();
    return _occurrencesBox.values
        .where((occurrence) =>
            occurrence.scheduledTime.isAfter(start) &&
            occurrence.scheduledTime.isBefore(end))
        .toList();
  }

  Future<void> deleteOccurrence(String id) async {
    _ensureInitialized();
    try {
      await _occurrencesBox.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete occurrence: $e');
    }
  }

  Future<void> deleteOccurrencesByCheckId(String checkId) async {
    _ensureInitialized();
    try {
      final occurrencesToDelete = _occurrencesBox.values
          .where((occurrence) => occurrence.checkId == checkId)
          .toList();
      
      for (final occurrence in occurrencesToDelete) {
        await _occurrencesBox.delete(occurrence.id);
      }
    } catch (e) {
      throw StorageException('Failed to delete occurrences for check: $e');
    }
  }

  // Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    _ensureInitialized();
    try {
      await _settingsBox.put(key, value);
    } catch (e) {
      throw StorageException('Failed to save setting: $e');
    }
  }

  T? getSetting<T>(String key, [T? defaultValue]) {
    _ensureInitialized();
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  Map<String, dynamic> getAllSettings() {
    _ensureInitialized();
    final map = <String, dynamic>{};
    for (final key in _settingsBox.keys) {
      map[key.toString()] = _settingsBox.get(key);
    }
    return map;
  }

  Future<void> deleteSetting(String key) async {
    _ensureInitialized();
    try {
      await _settingsBox.delete(key);
    } catch (e) {
      throw StorageException('Failed to delete setting: $e');
    }
  }

  // Utility methods
  Future<bool> isFirstLaunch() async {
    _ensureInitialized();
    final hasLaunched = getSetting<bool>('has_launched', false) ?? false;
    if (!hasLaunched) {
      await saveSetting('has_launched', true);
    }
    return !hasLaunched;
  }

  Future<void> clearAllData() async {
    _ensureInitialized();
    try {
      await _checksBox.clear();
      await _schedulesBox.clear();
      await _occurrencesBox.clear();
      await _settingsBox.clear();
    } catch (e) {
      throw StorageException('Failed to clear all data: $e');
    }
  }

  Future<Map<String, dynamic>> exportData() async {
    _ensureInitialized();
    try {
      return {
        'checks': getAllChecks().map((c) => c.toJson()).toList(),
        'schedules': getAllSchedules().map((s) => s.toJson()).toList(),
        'occurrences': getAllOccurrences().map((o) => o.toJson()).toList(),
        'settings': getAllSettings(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    } catch (e) {
      throw StorageException('Failed to export data: $e');
    }
  }

  Future<void> importData(Map<String, dynamic> data) async {
    _ensureInitialized();
    try {
      // Clear existing data
      await clearAllData();

      // Import checks
      if (data['checks'] != null) {
        for (final checkJson in data['checks']) {
          final check = Check.fromJson(checkJson);
          await saveCheck(check);
        }
      }

      // Import schedules
      if (data['schedules'] != null) {
        for (final scheduleJson in data['schedules']) {
          final schedule = Schedule.fromJson(scheduleJson);
          await saveSchedule(schedule);
        }
      }

      // Import occurrences
      if (data['occurrences'] != null) {
        for (final occurrenceJson in data['occurrences']) {
          final occurrence = ScheduleOccurrence.fromJson(occurrenceJson);
          await saveOccurrence(occurrence);
        }
      }

      // Import settings
      if (data['settings'] != null) {
        for (final entry in data['settings'].entries) {
          await saveSetting(entry.key, entry.value);
        }
      }
    } catch (e) {
      throw StorageException('Failed to import data: $e');
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StorageException('Storage not initialized. Call initialize() first.');
    }
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      await _checksBox.close();
      await _schedulesBox.close();
      await _occurrencesBox.close();
      await _settingsBox.close();
      _isInitialized = false;
    } catch (e) {
      throw StorageException('Failed to dispose storage: $e');
    }
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
