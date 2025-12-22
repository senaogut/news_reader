import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure storage operations
class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _enabledSourcesKey = 'enabled_source_ids';

  /// Save enabled source IDs
  static Future<void> saveEnabledSourceIds(List<String> sourceIds) async {
    try {
      final jsonString = jsonEncode(sourceIds);
      await _storage.write(key: _enabledSourcesKey, value: jsonString);
    } catch (e) {
      // Handle error silently or log it
      dev.log('Error saving enabled sources: $e');
    }
  }

  /// Load enabled source IDs
  static Future<List<String>> loadEnabledSourceIds() async {
    try {
      final jsonString = await _storage.read(key: _enabledSourcesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      // Handle error silently or log it
      dev.log('Error loading enabled sources: $e');
      return [];
    }
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      dev.log('Error clearing storage: $e');
    }
  }
}
