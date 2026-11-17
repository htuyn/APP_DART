import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/data/models/quiz_result_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/quiz_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/exam_provider.dart';

class MockQuizRepository implements IQuizRepository {
  List<String> wrongIds = [];
  List<QuizResultModel> history = [];

  @override
  Future<List<QuestionModel>> loadQuestions() async => [];

  @override
  Future<List<String>> getWrongQuestionIds() async => wrongIds;

  @override
  Future<void> saveWrongQuestion(String id) async {
    if (!wrongIds.contains(id)) wrongIds.add(id);
  }

  @override
  Future<void> removeWrongQuestion(String id) async {
    wrongIds.remove(id);
  }

  @override
  Future<List<QuizResultModel>> getQuizHistory() async => history;

  @override
  Future<void> saveQuizResult(QuizResultModel result) async {
    history.add(result);
  }
}

void main() {
  group('ExamProvider Unit Tests', () {
    late MockQuizRepository mockRepo;
    late ExamProvider examProvider;

    final dummyQuestions = List.generate(
      5,
      (i) => QuestionModel(
        id: 'Q$i',
        blockId: 1,
        blockName: const LocalizedText(vi: 'Khá»‘i 1', en: 'Block 1'),
        level: 'Nhá»›',
        question: LocalizedText(vi: 'CÃ¢u $i', en: 'Question $i'),
        optionsVi: ['A', 'B', 'C', 'D'],
        optionsEn: ['A', 'B', 'C', 'D'],
        correctIndex: 1, // 'B' is always correct
        explanation: const LocalizedText(vi: 'Giáº£i thÃ­ch', en: 'Explanation'),
      ),
    );

    setUp(() {
      mockRepo = MockQuizRepository();
      examProvider = ExamProvider(repository: mockRepo);
    });

    tearDown(() {
      examProvider.dispose();
    });

    test('startExam initializes exam questions and timer', () {
      examProvider.startExam(
        allQuestions: dummyQuestions,
        numberOfQuestions: 3,
        durationMinutes: 10,
      );

      expect(examProvider.examQuestions.length, 3);
      expect(examProvider.remainingSeconds, 600);
      expect(examProvider.isSubmitted, false);
      expect(examProvider.userAnswers.isEmpty, true);
    });

    test('selectAnswer records user choice', () {
      examProvider.startExam(
        allQuestions: dummyQuestions,
        numberOfQuestions: 3,
        durationMinutes: 10,
      );

      examProvider.selectAnswer(0, 1); // Question 0, chosen 1 (correct)
      examProvider.selectAnswer(1, 0); // Question 1, chosen 0 (wrong)

      expect(examProvider.userAnswers[0], 1);
      expect(examProvider.userAnswers[1], 0);
    });

    test('submitExam computes score and saves wrong questions accurately', () async {
      examProvider.startExam(
        allQuestions: dummyQuestions,
        numberOfQuestions: 3,
        durationMinutes: 10,
      );

      examProvider.selectAnswer(0, 1); // Correct
      examProvider.selectAnswer(1, 0); // Wrong
      // Question 2 is unanswered -> Wrong

      final result = await examProvider.submitExam();

      expect(result.score, 1);
      expect(result.totalQuestions, 3);
      expect(result.wrongQuestionIds.length, 2);
      expect(examProvider.isSubmitted, true);
      expect(mockRepo.history.length, 1);
    });
  });
}
