import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/models/achievement_certificate_model.dart';
import 'package:flutter_quiz_bilingual/data/models/gamification_model.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/data/models/quiz_result_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/i_blockchain_repository.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/i_gamification_repository.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/quiz_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/blockchain_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/course_progress_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/gamification_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/stats_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = '0x1111111111111111111111111111111111111111';

class _QuizRepository implements IQuizRepository {
  @override
  Future<List<QuestionModel>> loadQuestions() async => const [];
  @override
  Future<List<String>> getWrongQuestionIds() async => const [];
  @override
  Future<void> saveWrongQuestion(String questionId) async {}
  @override
  Future<void> removeWrongQuestion(String questionId) async {}
  @override
  Future<List<QuizResultModel>> getQuizHistory() async => [
        QuizResultModel(
          id: 'perfect',
          timestamp: DateTime.utc(2026),
          score: 10,
          totalQuestions: 10,
          timeSpentSeconds: 60,
          wrongQuestionIds: const [],
        ),
      ];
  @override
  Future<void> saveQuizResult(QuizResultModel result) async {}
}

class _GamificationRepository implements IGamificationRepository {
  @override
  Future<GamificationModel> load() async => GamificationModel();
  @override
  Future<void> save(GamificationModel progress) async {}
}

class _BlockchainRepository implements IBlockchainRepository {
  String? address = _wallet;
  final certificates = <AchievementCertificateModel>[];
  int saveCount = 0;
  bool relayerOffline = false;
  Map<String, dynamic>? issueResponse;

  @override
  Future<Map<String, dynamic>?> issueCertificate(AchievementCertificateModel certificate) async {
    if (relayerOffline) throw Exception('relayer offline');
    return issueResponse;
  }

  @override
  Future<void> saveCertificateRequest(AchievementCertificateModel certificate) async {
    saveCount++;
    final index = certificates.indexWhere((item) => item.certificateId == certificate.certificateId);
    if (index < 0) {
      certificates.add(certificate);
    } else {
      certificates[index] = certificate;
    }
  }
  @override
  Future<List<AchievementCertificateModel>> loadLocalCertificates() async => certificates;
  @override
  Future<List<AchievementCertificateModel>> loadCertificates({String? recipientAddress}) async => certificates;
  @override
  Future<AchievementCertificateModel?> verifyCertificate(String certificateId) async => null;
  @override
  Future<void> saveRecipientAddress(String value) async => address = value;
  @override
  Future<String?> loadRecipientAddress() async => address;
  @override
  Future<String?> loadEmbeddedAddress() async => address;
  @override
  Future<String?> loadEmbeddedPrivateKey() async => null;
  @override
  Future<void> useEmbeddedWallet() async {}
  @override
  Future<List<String>> findIssuedCertificateIds({required String recipientAddress, required int fromBlock, required int toBlock}) async => const [];
  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requesting an already pending achievement twice saves only one certificate', () async {
    SharedPreferences.setMockInitialValues({});
    final quizRepository = _QuizRepository();
    final stats = StatsProvider(repository: quizRepository);
    final course = CourseProgressProvider(
      repository: quizRepository,
      statsProvider: stats,
    );
    await course.initialize();

    final gamification = GamificationProvider(
      repository: _GamificationRepository(),
    );
    final blockchainRepository = _BlockchainRepository()..relayerOffline = true;
    final blockchain = BlockchainProvider(
      repository: blockchainRepository,
      gamificationProvider: gamification,
      courseProgressProvider: course,
      connectivityChanges: const Stream.empty(),
    );
    await blockchain.initialize();
    expect(
      blockchain.eligibleCertificates.any((item) => item.code == 'perfectScore'),
      isTrue,
    );

    final first = await blockchain.requestCertificate('perfectScore');
    final second = await blockchain.requestCertificate('perfectScore');

    expect(first, isNotNull);
    expect(first?.status, CertificateStatus.pending);
    expect(blockchain.noticeMessage, 'issuance_pending_notice');
    expect(second?.certificateId, first?.certificateId);
    expect(blockchainRepository.saveCount, 1);
    expect(blockchain.certificates, hasLength(1));

    blockchainRepository.relayerOffline = false;
    blockchainRepository.issueResponse = {
      'status': 'confirmed',
      'transactionHash': '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'blockNumber': 7654321,
      'issuedAt': DateTime.utc(2026, 1, 2).toIso8601String(),
    };
    await blockchain.synchronize();

    expect(blockchain.certificates.single.status, CertificateStatus.confirmed);
    expect(blockchain.certificates.single.transactionHash, '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    expect(blockchain.certificates.single.blockNumber, 7654321);
    expect(blockchain.noticeMessage, isNull);

    blockchain.dispose();
    course.dispose();
    gamification.dispose();
  });
}
