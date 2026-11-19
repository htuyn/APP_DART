import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/gamification_model.dart';
import 'auth_storage_datasource.dart';

/// Stores all gamification progress under one versioned SharedPreferences key.
class GamificationStorageDataSource {
  static const String baseStorageKey = 'gamification_v1';
  static const String storageKey = baseStorageKey;

  Future<String> _getStorageKey() async {
    final user = await AuthStorageDataSource().getCurrentUser();
    if (user != null && user.id.isNotEmpty) {
      return '${baseStorageKey}_${user.id}';
    }
    return baseStorageKey;
  }

  Future<GamificationModel> load() async {
    final preferences = await SharedPreferences.getInstance();
    final key = await _getStorageKey();
    final raw = preferences.getString(key);
    if (raw == null || raw.isEmpty) return GamificationModel();

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid gamification data');
    }
    return GamificationModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> save(GamificationModel progress) async {
    final preferences = await SharedPreferences.getInstance();
    final key = await _getStorageKey();
    await preferences.setString(key, jsonEncode(progress.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    final key = await _getStorageKey();
    await preferences.remove(key);
  }
}
