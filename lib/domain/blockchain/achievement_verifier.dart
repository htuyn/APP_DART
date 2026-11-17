import '../../data/models/achievement_certificate_model.dart';

class OnChainCertificate {
  const OnChainCertificate({
    required this.certificateId,
    required this.certificateType,
    required this.recipientAddress,
    required this.achievementHash,
    required this.issuedAt,
    required this.revoked,
    required this.valid,
  });

  final String certificateId;
  final int certificateType;
  final String recipientAddress;
  final String achievementHash;
  final DateTime issuedAt;
  final bool revoked;
  final bool valid;
}

class AchievementVerifier {
  const AchievementVerifier();

  AchievementCertificateModel reconcile(
    AchievementCertificateModel local,
    OnChainCertificate? onChain,
  ) {
    if (onChain == null) {
      return local.copyWith(status: CertificateStatus.pending);
    }

    final matches =
        _sameHex(local.certificateId, onChain.certificateId) &&
        local.type.chainValue == onChain.certificateType &&
        local.recipientAddress.toLowerCase() ==
            onChain.recipientAddress.toLowerCase() &&
        _sameHex(local.achievementHash, onChain.achievementHash);

    if (!matches) {
      return local.copyWith(status: CertificateStatus.failed);
    }

    if (onChain.revoked) {
      return local.copyWith(
        status: CertificateStatus.revoked,
        issuedAt: onChain.issuedAt,
      );
    }
    if (onChain.valid) {
      return local.copyWith(
        status: CertificateStatus.confirmed,
        issuedAt: onChain.issuedAt,
      );
    }
    return local.copyWith(status: CertificateStatus.unverified);
  }

  bool _sameHex(String a, String b) => a.toLowerCase() == b.toLowerCase();
}
