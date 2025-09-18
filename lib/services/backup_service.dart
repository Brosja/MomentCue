import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/simple_check.dart';

class BackupService {
  static const String _backupKey = 'momentcue_backup';
  static const String _encryptionKey = 'momentcue_encryption_key';
  
  /// Export all checks to a JSON file
  static Future<String> exportChecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checksJson = prefs.getStringList('checks') ?? [];
      
      final checks = checksJson
          .map((json) => SimpleCheck.fromJson(jsonDecode(json)))
          .toList();
      
      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'checks': checks.map((check) => check.toJson()).toList(),
      };
      
      final jsonString = jsonEncode(backupData);
      final encryptedData = _encryptData(jsonString);
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/momentcue_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      
      await file.writeAsString(encryptedData);
      
      if (kDebugMode) {
        print('Backup exported to: ${file.path}');
      }
      
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting backup: $e');
      }
      throw Exception('Failed to export backup: $e');
    }
  }
  
  /// Import checks from a JSON file
  static Future<void> importChecks(String filePath) async {
    try {
      final file = File(filePath);
      final encryptedData = await file.readAsString();
      final jsonString = _decryptData(encryptedData);
      
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      final checksJson = backupData['checks'] as List<dynamic>;
      
      final checks = checksJson
          .map((json) => SimpleCheck.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final prefs = await SharedPreferences.getInstance();
      final checksJsonList = checks
          .map((check) => jsonEncode(check.toJson()))
          .toList();
      
      await prefs.setStringList('checks', checksJsonList);
      
      if (kDebugMode) {
        print('Backup imported successfully: ${checks.length} checks');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error importing backup: $e');
      }
      throw Exception('Failed to import backup: $e');
    }
  }
  
  /// Get available backup files
  static Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .where((file) => file.path.contains('momentcue_backup_'))
          .toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting backup files: $e');
      }
      return [];
    }
  }
  
  /// Delete a backup file
  static Future<void> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      await file.delete();
      
      if (kDebugMode) {
        print('Backup file deleted: $filePath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting backup file: $e');
      }
      throw Exception('Failed to delete backup file: $e');
    }
  }
  
  /// Encrypt data using a simple encryption method
  static String _encryptData(String data) {
    // In a real app, you would use proper encryption
    // For now, we'll use base64 encoding as a simple obfuscation
    final bytes = utf8.encode(data);
    return base64Encode(bytes);
  }
  
  /// Decrypt data
  static String _decryptData(String encryptedData) {
    try {
      final bytes = base64Decode(encryptedData);
      return utf8.decode(bytes);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }
  
  /// Generate a backup summary
  static Future<Map<String, dynamic>> getBackupSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checksJson = prefs.getStringList('checks') ?? [];
      
      final checks = checksJson
          .map((json) => SimpleCheck.fromJson(jsonDecode(json)))
          .toList();
      
      final enabledChecks = checks.where((check) => check.enabled).length;
      final notificationChecks = checks.where((check) => check.notificationsEnabled).length;
      
      return {
        'totalChecks': checks.length,
        'enabledChecks': enabledChecks,
        'notificationChecks': notificationChecks,
        'lastModified': checks.isNotEmpty 
            ? checks.map((c) => c.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting backup summary: $e');
      }
      return {
        'totalChecks': 0,
        'enabledChecks': 0,
        'notificationChecks': 0,
        'lastModified': null,
      };
    }
  }
}
