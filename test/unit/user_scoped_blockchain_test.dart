import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/core/utils/certificate_hasher.dart';
import 'package:flutter_quiz_bilingual/data/datasources/auth_storage_datasource.dart';
import 'package:flutter_quiz_bilingual/data/datasources/blockchain_storage_datasource.dart';
import 'package:flutter_quiz_bilingual/data/models/achievement_certificate_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User-scoped Embedded Wallet & Certificate Hash Isolation', () {
    late AuthStorageDataSource authStorage;
    late BlockchainStorageDataSource blockchainStorage;
    const hasher = CertificateHasher();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      authStorage = AuthStorageDataSource();
      blockchainStorage = BlockchainStorageDataSource();
    });

    test('isolates embedded wallets and generates distinct achievementHashes for different Gmail accounts', () async {
      // 1. Register & login as User 1
      final user1 = await authStorage.register(
        email: 'user1@gmail.com',
        password: 'password123',
        name: 'User One',
      );
      expect(user1.email, 'user1@gmail.com');

      final address1 = await blockchainStorage.loadEmbeddedAddress();
      final privateKey1 = await blockchainStorage.loadEmbeddedPrivateKey();
      expect(address1, isNotNull);
      expect(privateKey1, isNotNull);

      final cert1Id = hasher.createCertificateId(
        subjectId: address1!,
        certificateType: 1,
        achievementCode: 'perfectScore',
        criteriaSnapshot: const {'score': 100},
        userIdentity: user1.email,
      );
      final hash1 = hasher.hashCertificate(
        subjectId: address1,
        certificateType: 1,
        achievementCode: 'perfectScore',
        criteriaSnapshot: const {'score': 100},
        userIdentity: user1.email,
      );

      final cert1 = AchievementCertificateModel(
        certificateId: cert1Id,
        subjectId: address1,
        type: CertificateType.achievement,
        achievementCode: 'perfectScore',
        recipientAddress: address1,
        achievementHash: hash1,
        criteriaSnapshot: const {'score': 100},
        requestedAt: DateTime.utc(2026),
        status: CertificateStatus.pending,
      );
      await blockchainStorage.saveCertificate(cert1);
      final user1Certs = await blockchainStorage.loadCertificates();
      expect(user1Certs, hasLength(1));
      expect(user1Certs.first.certificateId, cert1Id);

      // 2. Logout User 1 & Register/Login as User 2
      await authStorage.logout();
      final user2 = await authStorage.register(
        email: 'user2@gmail.com',
        password: 'password123',
        name: 'User Two',
      );
      expect(user2.email, 'user2@gmail.com');

      final address2 = await blockchainStorage.loadEmbeddedAddress();
      final privateKey2 = await blockchainStorage.loadEmbeddedPrivateKey();
      expect(address2, isNotNull);
      expect(privateKey2, isNotNull);

      // Embedded wallets must be completely distinct across different Gmail accounts
      expect(address1, isNot(equals(address2)));
      expect(privateKey1, isNot(equals(privateKey2)));

      // User 2's local certificate list should be isolated (empty initially)
      final user2Certs = await blockchainStorage.loadCertificates();
      expect(user2Certs, isEmpty);

      // Generating achievementHash for same achievement ('perfectScore') must include user2 identity
      final cert2Id = hasher.createCertificateId(
        subjectId: address2!,
        certificateType: 1,
        achievementCode: 'perfectScore',
        criteriaSnapshot: const {'score': 100},
        userIdentity: user2.email,
      );
      final hash2 = hasher.hashCertificate(
        subjectId: address2,
        certificateType: 1,
        achievementCode: 'perfectScore',
        criteriaSnapshot: const {'score': 100},
        userIdentity: user2.email,
      );

      // Verify that achievementHash and certificateId are distinct for different Gmail accounts
      expect(hash1, isNot(equals(hash2)));
      expect(cert1Id, isNot(equals(cert2Id)));

      final cert2 = AchievementCertificateModel(
        certificateId: cert2Id,
        subjectId: address2,
        type: CertificateType.achievement,
        achievementCode: 'perfectScore',
        recipientAddress: address2,
        achievementHash: hash2,
        criteriaSnapshot: const {'score': 100},
        requestedAt: DateTime.utc(2026),
        status: CertificateStatus.pending,
      );
      await blockchainStorage.saveCertificate(cert2);
      expect(await blockchainStorage.loadCertificates(), hasLength(1));

      // 3. Logout User 2 & Login back as User 1
      await authStorage.logout();
      await authStorage.login(
        email: 'user1@gmail.com',
        password: 'password123',
      );

      final restoredAddress1 = await blockchainStorage.loadEmbeddedAddress();
      final restoredCerts1 = await blockchainStorage.loadCertificates();

      expect(restoredAddress1, address1);
      expect(restoredCerts1, hasLength(1));
      expect(restoredCerts1.first.certificateId, cert1Id);
      expect(restoredCerts1.first.achievementHash, hash1);
    });
  });
}
