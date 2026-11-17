import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/data/models/quiz_result_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/quiz_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/course_progress_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/stats_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeQuizRepository implements IQuizRepository {
  _FakeQuizRepository(this.questions, {this.wrongIds = const [], this.history = const []});

  final List<QuestionModel> questions;
  final List<String> wrongIds;
  final List<QuizResultModel> history;

  @override
  Future<List<QuestionModel>> loadQuestions() async => questions;
  @override
  Future<List<String>> getWrongQuestionIds() async => wrongIds;
  @override
  Future<void> saveWrongQuestion(String questionId) async {}
  @override
  Future<void> removeWrongQuestion(String questionId) async {}
  @override
  Future<List<QuizResultModel>> getQuizHistory() async => history;
  @override
  Future<void> saveQuizResult(QuizResultModel result) async {}
}

QuestionModel _question(String id, int block) => QuestionModel(
      id: id,
      blockId: block,
      blockName: LocalizedText(vi: 'Khối $block', en: 'Block $block'),
      level: 'Nhớ',
      question: LocalizedText(vi: 'Câu $id', en: 'Question $id'),
      optionsVi: const ['A', 'B'],
      optionsEn: const ['A', 'B'],
      correctIndex: 0,
      explanation: const LocalizedText(vi: '', en: ''),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('aggregates completed blocks, practice count, accuracy and latest capstone', () async {
    SharedPreferences.setMockInitialValues({
      'course_practice_answer_count_v1': 200,
      'course_practice_correct_count_v1': 180,
      'course_attempted_question_ids_v1': ['q1', 'q2'],
      'course_mastered_question_ids_v1': ['q1', 'q2'],
    });
    final history = [
      QuizResultModel(
        id: 'regular',
        timestamp: DateTime.utc(2026, 1, 1),
        score: 8,
        totalQuestions: 10,
        timeSpentSeconds: 100,
        wrongQuestionIds: const [],
      ),
      QuizResultModel(
        id: 'capstone',
        timestamp: DateTime.utc(2026, 1, 2),
        score: 16,
        totalQuestions: 20,
        timeSpentSeconds: 200,
        wrongQuestionIds: const [],
        isCapstoneExam: true,
      ),
    ];
    final repository = _FakeQuizRepository(
      [_question('q1', 1), _question('q2', 2)],
      history: history,
    );
    final stats = StatsProvider(repository: repository);
    final provider = CourseProgressProvider(repository: repository, statsProvider: stats);

    await provider.initialize();

    expect(provider.totalBlockCount, 2);
    expect(provider.completedBlockCount, 2);
    expect(provider.practiceQuestionsAnswered, 200);
    expect(provider.overallAccuracyPercent, closeTo(88.7, 0.1));
    expect(provider.capstoneExamScore, 16);
    expect(provider.capstoneExamTotal, 20);
    expect(provider.certificateEligibility.eligible, isTrue);
  });

  test('derives practice thresholds from 30 and 100 question banks', () async {
    for (final size in [30, 100]) {
      SharedPreferences.setMockInitialValues({});
      final repository = _FakeQuizRepository(
        List.generate(size, (index) => _question('q$index', index % 4 + 1)),
      );
      final provider = CourseProgressProvider(
        repository: repository,
        statsProvider: StatsProvider(repository: repository),
      );

      await provider.initialize();

      expect(provider.totalQuestionsInBank, size);
      expect(provider.requiredPracticeQuestions, size == 30 ? 27 : 90);
      provider.dispose();
    }
  });

  test('a wrong question prevents the corresponding block from completing', () async {
    SharedPreferences.setMockInitialValues({
      'course_practice_answer_count_v1': 1,
      'course_practice_correct_count_v1': 1,
      'course_mastered_question_ids_v1': ['q1'],
    });
    final repository = _FakeQuizRepository(
      [_question('q1', 1), _question('q2', 1)],
      wrongIds: ['q2'],
    );
    final provider = CourseProgressProvider(
      repository: repository,
      statsProvider: StatsProvider(repository: repository),
    );

    await provider.initialize();

    expect(provider.completedBlockCount, 0);
    expect(provider.totalBlockCount, 1);
  });
}
