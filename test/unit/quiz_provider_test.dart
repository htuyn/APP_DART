import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/data/models/quiz_result_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/quiz_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/quiz_provider.dart';

class InMemoryQuizRepository implements IQuizRepository {
  List<QuestionModel> questions;
  List<String> wrongIds = [];
  List<QuizResultModel> history = [];

  InMemoryQuizRepository(this.questions);

  @override
  Future<List<QuestionModel>> loadQuestions() async => questions;

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
  group('QuizProvider Unit Tests', () {
    late InMemoryQuizRepository repo;
    late QuizProvider provider;

    final dummyList = [
      const QuestionModel(
        id: 'Q1',
        blockId: 1,
        blockName: LocalizedText(vi: 'Khá»‘i 1', en: 'Block 1'),
        level: 'Nhá»›',
        question: LocalizedText(vi: 'CÃ¢u 1', en: 'Question 1'),
        optionsVi: ['A', 'B', 'C', 'D'],
        optionsEn: ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        explanation: LocalizedText(vi: 'G1', en: 'E1'),
      ),
      const QuestionModel(
        id: 'Q2',
        blockId: 2,
        blockName: LocalizedText(vi: 'Khá»‘i 2', en: 'Block 2'),
        level: 'Hiá»ƒu',
        question: LocalizedText(vi: 'CÃ¢u 2', en: 'Question 2'),
        optionsVi: ['A', 'B', 'C', 'D'],
        optionsEn: ['A', 'B', 'C', 'D'],
        correctIndex: 1,
        explanation: LocalizedText(vi: 'G2', en: 'E2'),
      ),
    ];

    setUp(() {
      repo = InMemoryQuizRepository(dummyList);
      provider = QuizProvider(repository: repo);
    });

    test('initialize loads all questions into state', () async {
      expect(provider.state, QuizLoadingState.initial);
      await provider.initialize();
      expect(provider.state, QuizLoadingState.loaded);
      expect(provider.allQuestions.length, 2);
    });

    test('getQuestionsByBlock filters by block id properly', () async {
      await provider.initialize();
      final block1Questions = provider.getQuestionsByBlock(1);
      final block2Questions = provider.getQuestionsByBlock(2);

      expect(block1Questions.length, 1);
      expect(block1Questions.first.id, 'Q1');
      expect(block2Questions.length, 1);
      expect(block2Questions.first.id, 'Q2');
    });

    test('groupedByBlock groups all questions into a map', () async {
      await provider.initialize();
      final grouped = provider.groupedByBlock;

      expect(grouped.containsKey(1), true);
      expect(grouped.containsKey(2), true);
      expect(grouped[1]?.first.id, 'Q1');
    });

    test('recordAnswer saves question into wrong questions if incorrect', () async {
      await provider.initialize();
      await provider.recordAnswer(question: dummyList[0], isCorrect: false);

      expect(provider.wrongQuestionIds.contains('Q1'), true);
      expect(provider.wrongQuestions.length, 1);
      expect(repo.wrongIds.contains('Q1'), true);
    });

    test('recordAnswer removes question from wrong questions if answered correctly', () async {
      await provider.initialize();
      // First wrong
      await provider.recordAnswer(question: dummyList[0], isCorrect: false);
      expect(provider.wrongQuestionIds.contains('Q1'), true);

      // Retake and correct
      await provider.recordAnswer(question: dummyList[0], isCorrect: true);
      expect(provider.wrongQuestionIds.contains('Q1'), false);
      expect(provider.wrongQuestions.isEmpty, true);
    });
  });
}
