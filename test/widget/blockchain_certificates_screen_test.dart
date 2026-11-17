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
import 'package:flutter_quiz_bilingual/presentation/screens/blockchain_certificates_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _wallet = '0x1111111111111111111111111111111111111111';

AchievementCertificateModel _certificate(int index, CertificateType type, CertificateStatus status) =>
    AchievementCertificateModel(
      certificateId: '0x${index.toRadixString(16).padLeft(64, '0')}',
      subjectId: _wallet,
      type: type,
      achievementCode: index == 5 ? 'course_completion' : 'perfectScore',
      recipientAddress: _wallet,
      achievementHash: '0x${(index + 10).toRadixString(16).padLeft(64, '0')}',
      criteriaSnapshot: const {'score': 100},
      requestedAt: DateTime.utc(2026),
      status: status,
      transactionHash: '0x${(index + 20).toRadixString(16).padLeft(64, '0')}',
    );

class _FakeBlockchainRepository implements IBlockchainRepository {
  final values = [
    _certificate(1, CertificateType.achievement, CertificateStatus.eligible),
    _certificate(2, CertificateType.achievement, CertificateStatus.pending),
    _certificate(3, CertificateType.achievement, CertificateStatus.confirmed),
    _certificate(4, CertificateType.achievement, CertificateStatus.revoked),
    _certificate(5, CertificateType.courseCompletion, CertificateStatus.failed),
  ];
  String? address;

  @override
  Future<void> saveCertificateRequest(AchievementCertificateModel certificate) async {
    values.add(certificate);
  }
  @override
  Future<List<AchievementCertificateModel>> loadLocalCertificates() async => values;
  @override
  Future<List<AchievementCertificateModel>> loadCertificates({String? recipientAddress}) async => values;
  @override
  Future<AchievementCertificateModel?> verifyCertificate(String certificateId) async =>
      values.where((item) => item.certificateId == certificateId).firstOrNull;
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
  Future<Map<String, dynamic>?> issueCertificate(AchievementCertificateModel certificate) async => null;
  @override
  Future<List<String>> findIssuedCertificateIds({required String recipientAddress, required int fromBlock, required int toBlock}) async => const [];
  @override
  Future<void> dispose() async {}
}

class _FakeQuizRepository implements IQuizRepository {
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

class _FakeGamificationRepository implements IGamificationRepository {
  @override
  Future<GamificationModel> load() async => GamificationModel();
  @override
  Future<void> save(GamificationModel progress) async {}
}

Future<(BlockchainProvider, CourseProgressProvider, GamificationProvider, LanguageProvider)> _providers() async {
  SharedPreferences.setMockInitialValues({});
  final quizRepository = _FakeQuizRepository();
  final gamification = GamificationProvider(repository: _FakeGamificationRepository());
  final stats = StatsProvider(repository: quizRepository);
  final course = CourseProgressProvider(repository: quizRepository, statsProvider: stats);
  final blockchain = BlockchainProvider(
    repository: _FakeBlockchainRepository(),
    gamificationProvider: gamification,
    courseProgressProvider: course,
    connectivityChanges: const Stream.empty(),
  );
  await blockchain.initialize();
  return (blockchain, course, gamification, LanguageProvider());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('validates wallet and renders both certificate types and statuses', (tester) async {
    final (blockchain, course, gamification, language) = await _providers();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: blockchain),
          ChangeNotifierProvider.value(value: course),
          ChangeNotifierProvider.value(value: gamification),
          ChangeNotifierProvider.value(value: language),
        ],
        child: const MaterialApp(home: BlockchainCertificatesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Äá»•i vÃ­ MetaMask'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'bad-wallet');
    await tester.tap(find.text('LÆ°u Ä‘á»‹a chá»‰ vÃ­'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Äá»‹a chá»‰ vÃ­ khÃ´ng há»£p lá»‡'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), _wallet);
    await tester.tap(find.text('LÆ°u Ä‘á»‹a chá»‰ vÃ­'));
    await tester.pumpAndSettle();
    expect(find.text('Äá»‹a chá»‰ vÃ­ khÃ´ng há»£p lá»‡. Äá»‹a chá»‰ cáº§n báº¯t Ä‘áº§u báº±ng 0x vÃ  cÃ³ 40 kÃ½ tá»± hex.'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Chá»©ng chá»‰ cá»§a báº¡n'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Chá»©ng chá»‰ thÃ nh tÃ­ch'), findsWidgets);
    expect(find.text('Chá»©ng chá»‰ hoÃ n thÃ nh khÃ³a há»c'), findsWidgets);
    expect(find.text('Äá»§ Ä‘iá»u kiá»‡n'), findsWidgets);
    expect(find.text('Äang chá»'), findsWidgets);
    expect(find.text('ÄÃ£ xÃ¡c nháº­n'), findsWidgets);
    expect(find.text('ÄÃ£ thu há»“i'), findsWidgets);
    expect(find.text('Tháº¥t báº¡i'), findsWidgets);

    blockchain.dispose();
    course.dispose();
    gamification.dispose();
    language.dispose();
  });
}
