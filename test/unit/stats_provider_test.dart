import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/data/models/quiz_result_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/quiz_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/stats_provider.dart';

class DummyRepo implements IQuizRepository {
  List<QuizResultModel> history = [];

  @override
  Future<List<QuestionModel>> loadQuestions() async => [];

  @override
  Future<List<String>> getWrongQuestionIds() async => [];

  @override
  Future<void> saveWrongQuestion(String id) async {}

  @override
  Future<void> removeWrongQuestion(String id) async {}

  @override
  Future<List<QuizResultModel>> getQuizHistory() async => history;

  @override
  Future<void> saveQuizResult(QuizResultModel result) async {
    history.add(result);
  }
}

void main() {
  group('StatsProvider Unit Tests', () {
    late DummyRepo repo;
    late StatsProvider statsProvider;

    setUp(() {
      repo = DummyRepo();
      statsProvider = StatsProvider(repository: repo);
    });

    test('calculateBlockStats calculates correct percentage and wrong counts', () {
      final questions = [
        const QuestionModel(
          id: 'Q1',
          blockId: 1,
          blockName: LocalizedText(vi: 'Khối 1', en: 'Block 1'),
          level: 'Nhớ',
          question: LocalizedText(vi: 'C1', en: 'Q1'),
          optionsVi: ['A', 'B'],
          optionsEn: ['A', 'B'],
          correctIndex: 0,
          explanation: LocalizedText(vi: 'G1', en: 'E1'),
        ),
        const QuestionModel(
          id: 'Q2',
          blockId: 1,
          blockName: LocalizedText(vi: 'Khối 1', en: 'Block 1'),
          level: 'Nhớ',
          question: LocalizedText(vi: 'C2', en: 'Q2'),
          optionsVi: ['A', 'B'],
          optionsEn: ['A', 'B'],
          correctIndex: 0,
          explanation: LocalizedText(vi: 'G2', en: 'E2'),
        ),
      ];

      // Q1 is wrong
      final stats = statsProvider.calculateBlockStats(
        allQuestions: questions,
        wrongIds: {'Q1'},
        langCode: 'vi',
      );

      expect(stats.length, 1);
      expect(stats.first.blockId, 1);
      expect(stats.first.totalQuestions, 2);
      expect(stats.first.wrongQuestions, 1);
      expect(stats.first.correctCount, 1);
      expect(stats.first.accuracyRate, 50.0);
    });

    test('BlockStat properties return accurate values for 100% correct', () {
      final stat = BlockStat(
        blockId: 2,
        blockTitle: 'Công cụ',
        totalQuestions: 5,
        wrongQuestions: 0,
      );

      expect(stat.correctCount, 5);
      expect(stat.accuracyRate, 100.0);
    });

    test('loadHistory updates history from repository', () async {
      repo.history = [
        QuizResultModel(
          id: '1',
          timestamp: DateTime.now(),
          score: 18,
          totalQuestions: 20,
          timeSpentSeconds: 400,
          wrongQuestionIds: ['Q1', 'Q2'],
        ),
      ];

      await statsProvider.loadHistory();
      expect(statsProvider.history.length, 1);
      expect(statsProvider.history.first.score, 18);
    });
  });
}
