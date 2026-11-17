import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/datasources/blockchain_storage_datasource.dart';
import 'package:flutter_quiz_bilingual/data/datasources/ethereum_blockchain_datasource.dart';
import 'package:flutter_quiz_bilingual/data/models/achievement_certificate_model.dart';
import 'package:flutter_quiz_bilingual/data/repositories/blockchain_repository_impl.dart';
import 'package:flutter_quiz_bilingual/domain/blockchain/achievement_verifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = '0x1111111111111111111111111111111111111111';
const _id = '0x1111111111111111111111111111111111111111111111111111111111111111';
const _hash = '0x2222222222222222222222222222222222222222222222222222222222222222';

AchievementCertificateModel _certificate({
  CertificateStatus status = CertificateStatus.pending,
}) => AchievementCertificateModel(
      certificateId: _id,
      subjectId: _wallet,
      type: CertificateType.achievement,
      achievementCode: 'perfectScore',
      recipientAddress: _wallet,
      achievementHash: _hash,
      criteriaSnapshot: const {'score': 100},
      requestedAt: DateTime.utc(2026),
      status: status,
    );

class _MemoryStorage extends BlockchainStorageDataSource {
  final records = <String, AchievementCertificateModel>{};
  String? address;

  @override
  Future<void> saveCertificate(AchievementCertificateModel certificate) async {
    records[certificate.certificateId] = certificate;
  }

  @override
  Future<List<AchievementCertificateModel>> loadCertificates() async =>
      records.values.toList();

  @override
  Future<void> saveRecipientAddress(String value) async => address = value;

  @override
  Future<String?> loadRecipientAddress() async => address;
}

class _FakeEthereum implements EthereumBlockchainDataSource {
  OnChainCertificate? record;
  IssuedCertificateEvent? issueEvent;
  bool shouldFail = false;

  @override
  Future<Map<String, dynamic>?> issueCertificate({required String certificateId, required int certificateType, required String recipientAddress, required String achievementHash}) async => null;

  @override
  Future<OnChainCertificate?> verifyCertificate(String certificateId) async {
    if (shouldFail) throw Exception('offline');
    return record;
  }

  @override
  Future<IssuedCertificateEvent?> findCertificateIssuedEvent(
    String certificateId,
  ) async => issueEvent;

  @override
  Future<List<String>> findIssuedCertificateIds({
    required String recipientAddress,
    required int fromBlock,
    required int toBlock,
  }) async => const [];

  @override
  Future<void> dispose() async {}
}

OnChainCertificate _onChain({bool revoked = false}) => OnChainCertificate(
      certificateId: _id,
      certificateType: 1,
      recipientAddress: _wallet,
      achievementHash: _hash,
      issuedAt: DateTime.utc(2026, 1, 2),
      revoked: revoked,
      valid: !revoked,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryStorage storage;
  late _FakeEthereum ethereum;
  late BlockchainRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = _MemoryStorage();
    ethereum = _FakeEthereum();
    repository = BlockchainRepositoryImpl(storage: storage, ethereum: ethereum);
  });

  test('generates and persists a reusable embedded wallet on first read', () async {
    final walletStorage = BlockchainStorageDataSource();
    final firstAddress = await walletStorage.ensureEmbeddedWallet();
    final firstKey = await walletStorage.loadEmbeddedPrivateKey();
    final activeAddress = await walletStorage.loadRecipientAddress();
    final secondAddress = await walletStorage.ensureEmbeddedWallet();

    expect(firstAddress, matches(RegExp(r'^0x[0-9a-fA-F]{40}$')));
    expect(firstKey, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(activeAddress, firstAddress);
    expect(secondAddress, firstAddress);
  });

  test('saves certificate request and recipient locally', () async {
    final certificate = _certificate();
    await repository.saveCertificateRequest(certificate);

    expect(storage.records[_id], same(certificate));
    expect(storage.address, _wallet);
    expect(await repository.loadLocalCertificates(), [certificate]);
  });

  test('synchronization reconciles pending into confirmed', () async {
    await repository.saveCertificateRequest(_certificate());
    ethereum.record = _onChain();
    ethereum.issueEvent = const IssuedCertificateEvent(
      certificateId: _id,
      transactionHash:
          '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      blockNumber: 7654321,
    );

    final results = await repository.loadCertificates(recipientAddress: _wallet);

    expect(results.single.status, CertificateStatus.confirmed);
    expect(results.single.transactionHash, ethereum.issueEvent?.transactionHash);
    expect(results.single.blockNumber, 7654321);
    expect(storage.records[_id]?.transactionHash, ethereum.issueEvent?.transactionHash);
    expect(storage.records[_id]?.blockNumber, 7654321);
  });

  test('persists transaction hash and block number in SharedPreferences', () async {
    final persistentStorage = BlockchainStorageDataSource();
    final persistentRepository = BlockchainRepositoryImpl(
      storage: persistentStorage,
      ethereum: ethereum,
    );
    ethereum.record = _onChain();
    ethereum.issueEvent = const IssuedCertificateEvent(
      certificateId: _id,
      transactionHash:
          '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      blockNumber: 8765432,
    );
    await persistentRepository.saveCertificateRequest(_certificate());

    final refreshed = await persistentRepository.verifyCertificate(_id);
    final restored = (await persistentStorage.loadCertificates()).single;

    expect(refreshed?.transactionHash, ethereum.issueEvent?.transactionHash);
    expect(refreshed?.blockNumber, 8765432);
    expect(restored.transactionHash, ethereum.issueEvent?.transactionHash);
    expect(restored.blockNumber, 8765432);
    await persistentRepository.dispose();
  });

  test('synchronization detects a revoked on-chain record', () async {
    await repository.saveCertificateRequest(_certificate());
    ethereum.record = _onChain(revoked: true);

    final results = await repository.loadCertificates(recipientAddress: _wallet);

    expect(results.single.status, CertificateStatus.revoked);
    expect(storage.records[_id]?.status, CertificateStatus.revoked);
  });

  test('propagates RPC failure and leaves the local pending request intact', () async {
    await repository.saveCertificateRequest(_certificate());
    ethereum.shouldFail = true;

    await expectLater(
      repository.loadCertificates(recipientAddress: _wallet),
      throwsException,
    );
    expect(storage.records[_id]?.status, CertificateStatus.pending);
    expect(await repository.loadLocalCertificates(), hasLength(1));
  });

  tearDown(() async => repository.dispose());
}
