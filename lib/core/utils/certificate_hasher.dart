import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'achievement_hasher.dart';

/// Creates deterministic SHA-256 values for a certificate and its chain ID.
class CertificateHasher {
  const CertificateHasher();

  final AchievementHasher _achievementHasher = const AchievementHasher();

  /// Hashes the subject, type, achievement code, and canonical criteria.
  String hashCertificate({
    required String subjectId,
    required int certificateType,
    required String achievementCode,
    required Map<String, dynamic> criteriaSnapshot,
  }) => _achievementHasher.hash(
    subjectId: subjectId,
    certificateType: certificateType,
    achievementCode: achievementCode,
    criteria: criteriaSnapshot,
  );

  /// Derives a separate bytes32 certificate ID from its achievement hash.
  String createCertificateId({
    required String subjectId,
    required int certificateType,
    required String achievementCode,
    required Map<String, dynamic> criteriaSnapshot,
  }) {
    final achievementHash = hashCertificate(
      subjectId: subjectId,
      certificateType: certificateType,
      achievementCode: achievementCode,
      criteriaSnapshot: criteriaSnapshot,
    );
    final digest = sha256.convert(
      utf8.encode('app-dart-certificate-id-v1:$achievementHash'),
    );
    return '0x${digest.toString()}';
  }
}
