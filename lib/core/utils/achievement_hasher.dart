import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Produces stable SHA-256 identifiers from canonical achievement data.
class AchievementHasher {
  const AchievementHasher();

  String hash({
    required String subjectId,
    required int certificateType,
    required String achievementCode,
    required Map<String, dynamic> criteria,
  }) {
    final payload = <String, dynamic>{
      'schema': 'app-dart-certificate-v1',
      'subject_id': subjectId.trim(),
      'certificate_type': certificateType,
      'achievement_code': achievementCode.trim(),
      'criteria': _canonicalize(criteria),
    };
    final digest = sha256.convert(utf8.encode(jsonEncode(payload)));
    return '0x${digest.toString()}';
  }

  static dynamic _canonicalize(dynamic value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return <String, dynamic>{
        for (final entry in entries)
          entry.key.toString(): _canonicalize(entry.value),
      };
    }
    if (value is Set) {
      final items = value.map(_canonicalize).toList()
        ..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));
      return items;
    }
    if (value is Iterable) return value.map(_canonicalize).toList();
    return value;
  }
}
