import '../../data/models/achievement_certificate_model.dart';

abstract interface class IBlockchainRepository {
  Future<void> saveCertificateRequest(AchievementCertificateModel certificate);

  Future<List<AchievementCertificateModel>> loadLocalCertificates();

  Future<List<AchievementCertificateModel>> loadCertificates({
    String? recipientAddress,
  });

  Future<AchievementCertificateModel?> verifyCertificate(String certificateId);

  Future<void> saveRecipientAddress(String address);

  Future<String?> loadRecipientAddress();

  Future<String?> loadEmbeddedAddress();

  Future<String?> loadEmbeddedPrivateKey();

  Future<void> useEmbeddedWallet();

  Future<Map<String, dynamic>?> issueCertificate(AchievementCertificateModel certificate);

  Future<List<String>> findIssuedCertificateIds({
    required String recipientAddress,
    required int fromBlock,
    required int toBlock,
  });

  Future<void> dispose();
}
