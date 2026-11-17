import '../../domain/blockchain/achievement_verifier.dart';
import '../../domain/repositories/i_blockchain_repository.dart';
import '../datasources/blockchain_storage_datasource.dart';
import '../datasources/ethereum_blockchain_datasource.dart';
import '../models/achievement_certificate_model.dart';

class BlockchainRepositoryImpl implements IBlockchainRepository {
  BlockchainRepositoryImpl({
    required this.storage,
    required this.ethereum,
    this.verifier = const AchievementVerifier(),
  });

  final BlockchainStorageDataSource storage;
  final EthereumBlockchainDataSource ethereum;
  final AchievementVerifier verifier;

  @override
  Future<void> saveCertificateRequest(
    AchievementCertificateModel certificate,
  ) async {
    await storage.saveRecipientAddress(certificate.recipientAddress);
    await storage.saveCertificate(certificate);
  }

  @override
  Future<List<AchievementCertificateModel>> loadLocalCertificates() =>
      storage.loadCertificates();

  @override
  Future<List<AchievementCertificateModel>> loadCertificates({
    String? recipientAddress,
  }) async {
    final requestedAddress =
        recipientAddress ?? await storage.loadRecipientAddress();
    final local = await storage.loadCertificates();
    final selected = requestedAddress == null
        ? local
        : local
            .where(
              (certificate) =>
                  certificate.recipientAddress.toLowerCase() ==
                  requestedAddress.toLowerCase(),
            )
            .toList(growable: false);

    return Future.wait(
      selected.map((certificate) async {
        final reconciled = await _verifyAndAttachTransactionMetadata(certificate);
        await storage.saveCertificate(reconciled);
        return reconciled;
      }),
    );
  }

  @override
  Future<AchievementCertificateModel?> verifyCertificate(
    String certificateId,
  ) async {
    final local = (await storage.loadCertificates()).where(
      (certificate) =>
          certificate.certificateId.toLowerCase() == certificateId.toLowerCase(),
    );
    if (local.isEmpty) return null;

    final certificate = local.first;
    final refreshed = await _verifyAndAttachTransactionMetadata(certificate);
    await storage.saveCertificate(refreshed);
    return refreshed;
  }

  Future<AchievementCertificateModel> _verifyAndAttachTransactionMetadata(
    AchievementCertificateModel certificate,
  ) async {
    final chainRecord = await ethereum.verifyCertificate(
      certificate.certificateId,
    );
    var reconciled = verifier.reconcile(certificate, chainRecord);
    if (chainRecord == null) return reconciled;

    try {
      final event = await ethereum.findCertificateIssuedEvent(
        certificate.certificateId,
      );
      if (event != null) {
        reconciled = reconciled.copyWith(
          transactionHash: event.transactionHash,
          blockNumber: event.blockNumber,
        );
      }
    } catch (_) {
      // Keep the on-chain verification result even if this RPC cannot query logs.
    }
    return reconciled;
  }

  @override
  Future<void> saveRecipientAddress(String address) =>
      storage.saveRecipientAddress(address);

  @override
  Future<String?> loadRecipientAddress() => storage.loadRecipientAddress();

  @override
  Future<List<String>> findIssuedCertificateIds({
    required String recipientAddress,
    required int fromBlock,
    required int toBlock,
  }) => ethereum.findIssuedCertificateIds(
    recipientAddress: recipientAddress,
    fromBlock: fromBlock,
    toBlock: toBlock,
  );

  @override
  Future<void> dispose() => ethereum.dispose();
}
