import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'achievement_hasher.dart';

/// Creates deterministic SHA-256 values for a certificate and its chain ID.
class CertificateHasher {
  const CertificateHasher();

  final AchievementHasher _achievementHasher = const AchievementHasher();

  /// Hashes the subject, type, achievement code, canonical criteria, and optional user identity.
  String hashCertificate({
    required String subjectId,
    required int certificateType,
    required String achievementCode,
    required Map<String, dynamic> criteriaSnapshot,
    String? userIdentity,
  }) => _achievementHasher.hash(
    subjectId: subjectId,
    certificateType: certificateType,
    achievementCode: achievementCode,
    criteria: criteriaSnapshot,
    userIdentity: userIdentity,
  );

  /// Derives a separate bytes32 certificate ID from its achievement hash.
  String createCertificateId({
    required String subjectId,
    required int certificateType,
    required String achievementCode,
    required Map<String, dynamic> criteriaSnapshot,
    String? userIdentity,
  }) {
    final achievementHash = hashCertificate(
      subjectId: subjectId,
      certificateType: certificateType,
      achievementCode: achievementCode,
      criteriaSnapshot: criteriaSnapshot,
      userIdentity: userIdentity,
    );
    final digest = sha256.convert(
      utf8.encode('app-dart-certificate-id-v1:$achievementHash'),
    );
    return '0x${digest.toString()}';
  }
}
