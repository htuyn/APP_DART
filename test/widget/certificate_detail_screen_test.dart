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
import 'package:flutter_quiz_bilingual/presentation/providers/language_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/stats_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/screens/certificate_detail_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = '0x1111111111111111111111111111111111111111';
const _txHash = '0x3333333333333333333333333333333333333333333333333333333333333333';
final _certificate = AchievementCertificateModel(
  certificateId: '0x1111111111111111111111111111111111111111111111111111111111111111',
  subjectId: _wallet,
  type: CertificateType.achievement,
  achievementCode: 'perfectScore',
  recipientAddress: _wallet,
  achievementHash: '0x2222222222222222222222222222222222222222222222222222222222222222',
  criteriaSnapshot: {'score': 100},
  requestedAt: DateTime.utc(2026),
  status: CertificateStatus.confirmed,
  issuedAt: DateTime.utc(2026, 1, 2),

);

class _BlockchainRepository implements IBlockchainRepository {
  @override
  Future<void> saveCertificateRequest(AchievementCertificateModel certificate) async {}
  @override
  Future<List<AchievementCertificateModel>> loadLocalCertificates() async => [_certificate];
  @override
  Future<List<AchievementCertificateModel>> loadCertificates({String? recipientAddress}) async => [_certificate];
  @override
  Future<AchievementCertificateModel?> verifyCertificate(String certificateId) async =>
      _certificate.copyWith(transactionHash: _txHash, blockNumber: 7654321);
  @override
  Future<void> saveRecipientAddress(String address) async {}
  @override
  Future<String?> loadRecipientAddress() async => _wallet;
  @override
  Future<List<String>> findIssuedCertificateIds({required String recipientAddress, required int fromBlock, required int toBlock}) async => const [];
  @override
  Future<void> dispose() async {}
}

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
  Future<List<QuizResultModel>> getQuizHistory() async => const [];
  @override
  Future<void> saveQuizResult(QuizResultModel result) async {}
}

class _GamificationRepository implements IGamificationRepository {
  @override
  Future<GamificationModel> load() async => GamificationModel();
  @override
  Future<void> save(GamificationModel progress) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows certificate hashes and can run on-chain verification', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final quiz = _QuizRepository();
    final gamification = GamificationProvider(repository: _GamificationRepository());
    final course = CourseProgressProvider(
      repository: quiz,
      statsProvider: StatsProvider(repository: quiz),
    );
    final blockchain = BlockchainProvider(
      repository: _BlockchainRepository(),
      gamificationProvider: gamification,
      courseProgressProvider: course,
      connectivityChanges: const Stream.empty(),
    );
    final language = LanguageProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: blockchain),
          ChangeNotifierProvider.value(value: course),
          ChangeNotifierProvider.value(value: gamification),
          ChangeNotifierProvider.value(value: language),
        ],
        child: MaterialApp(home: CertificateDetailScreen(certificate: _certificate)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_certificate.achievementHash), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Xác minh On-chain'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Xác minh On-chain'), findsOneWidget);
    await tester.tap(find.text('Xác minh On-chain'));
    await tester.pumpAndSettle();
    expect(find.text('Chứng chỉ hợp lệ trên blockchain.'), findsOneWidget);
    expect(find.text(_txHash), findsOneWidget);
    expect(find.text('7654321'), findsOneWidget);
    final explorerButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(explorerButton.onPressed, isNotNull);

    blockchain.dispose();
    course.dispose();
    gamification.dispose();
    language.dispose();
  });
}
