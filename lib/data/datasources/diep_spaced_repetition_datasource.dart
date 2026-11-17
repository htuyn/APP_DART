import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/diep_spaced_repetition_model.dart';

class SpacedRepetitionDataSource {
  static const String _prefsKey = 'spaced_repetition_data';

  /// Load all entries from SharedPreferences.
  /// Returns an empty map if no data has been saved yet.
  Future<Map<String, SpacedRepetitionEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};

    final Map<String, dynamic> decoded =
        (jsonDecode(raw) as Map<String, dynamic>);

    final result = <String, SpacedRepetitionEntry>{};
    for (final entry in decoded.entries) {
      try {
        result[entry.key] =
            SpacedRepetitionEntry.fromJson(entry.value as Map<String, dynamic>);
      } catch (_) {
        // Skip malformed entries rather than crashing the app.
      }
    }
    return result;
  }

  /// Persist the entire map to SharedPreferences (full overwrite).
  Future<void> saveAll(Map<String, SpacedRepetitionEntry> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      data.map((key, entry) => MapEntry(key, entry.toJson())),
    );
    await prefs.setString(_prefsKey, encoded);
  }

  /// Insert a new entry or update an existing one (keyed by questionId).
  Future<void> upsertEntry(SpacedRepetitionEntry entry) async {
    final data = await loadAll();
    data[entry.questionId] = entry;
    await saveAll(data);
  }

  /// Remove a single entry by questionId. No-op if the key does not exist.
  Future<void> removeEntry(String questionId) async {
    final data = await loadAll();
    if (data.containsKey(questionId)) {
      data.remove(questionId);
      await saveAll(data);
    }
  }
}
