import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';
import '../models/simple_check.dart';
import 'simple_storage_service.dart';

class BackupService {
  static const String _backupKey = 'momentcue_backup';
  static const String _encryptionKey = 'momentcue_encryption_key_v1';
  static const FlutterSecureStorage _secure = FlutterSecureStorage();
  static final Cipher _cipher = AesGcm.with256bits();
  
  /// Export all checks to a JSON file
  static Future<String> exportChecks() async {
    try {
      // Use the same source of truth as the app
      final checks = await SimpleStorageService.instance.getChecks();
      
      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'checks': checks.map((check) => check.toJson()).toList(),
      };
      
      final jsonString = jsonEncode(backupData);
      final encryptedData = await _encryptData(jsonString);
      
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
      final jsonString = await _decryptData(encryptedData);
      
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      final checksJson = backupData['checks'] as List<dynamic>;
      
      final checks = checksJson
          .map((json) => SimpleCheck.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Save via SimpleStorageService
      await SimpleStorageService.instance.saveChecks(checks);
      
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
  
  static Future<String> _encryptData(String data) async {
    final keyBytes = await _getOrCreateKey();
    final secretKey = SecretKey(keyBytes);
    final nonce = _randomBytes(12);
    final message = utf8.encode(data);
    final secretBox = await _cipher.encrypt(message, secretKey: secretKey, nonce: nonce);
    final payload = {
      'n': base64Encode(nonce),
      'c': base64Encode(secretBox.cipherText),
      't': base64Encode(secretBox.mac.bytes),
    };
    return jsonEncode(payload);
  }

  static Future<String> _decryptData(String encryptedData) async {
    try {
      final map = jsonDecode(encryptedData) as Map<String, dynamic>;
      final nonce = base64Decode(map['n'] as String);
      final cipherText = base64Decode(map['c'] as String);
      final macBytes = base64Decode(map['t'] as String);
      final keyBytes = await _getOrCreateKey();
      final secretKey = SecretKey(keyBytes);
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));
      final clear = await _cipher.decrypt(secretBox, secretKey: secretKey);
      return utf8.decode(clear);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  static Future<List<int>> _getOrCreateKey() async {
    final existing = await _secure.read(key: _encryptionKey);
    if (existing != null) {
      return base64Decode(existing);
    }
    final key = _randomBytes(32);
    await _secure.write(key: _encryptionKey, value: base64Encode(key));
    return key;
  }

  static List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
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
