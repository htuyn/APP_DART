import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/gamification_model.dart';

/// Stores all gamification progress under one versioned SharedPreferences key.
class GamificationStorageDataSource {
  static const String storageKey = 'gamification_v1';

  Future<GamificationModel> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return GamificationModel();

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid gamification data');
    }
    return GamificationModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> save(GamificationModel progress) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(storageKey, jsonEncode(progress.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(storageKey);
  }
}
