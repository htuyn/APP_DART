import 'package:flutter/foundation.dart';
import '../../data/models/question_model.dart';
import '../../data/models/quiz_result_model.dart';
import '../../domain/repositories/quiz_repository.dart';

class BlockStat {
  final int blockId;
  final String blockTitle;
  final int totalQuestions;
  final int wrongQuestions;

  BlockStat({
    required this.blockId,
    required this.blockTitle,
    required this.totalQuestions,
    required this.wrongQuestions,
  });

  int get correctCount => (totalQuestions - wrongQuestions).clamp(0, totalQuestions);
  double get accuracyRate =>
      totalQuestions == 0 ? 0.0 : (correctCount / totalQuestions) * 100.0;
}

class StatsProvider with ChangeNotifier {
  final IQuizRepository repository;

  List<QuizResultModel> _history = [];
  List<QuizResultModel> get history => _history;

  StatsProvider({required this.repository});

  Future<void> loadHistory() async {
    _history = await repository.getQuizHistory();
    notifyListeners();
  }

  List<BlockStat> calculateBlockStats({
    required List<QuestionModel> allQuestions,
    required Set<String> wrongIds,
    required String langCode,
  }) {
    final Map<int, List<QuestionModel>> blockMap = {};
    for (final q in allQuestions) {
      blockMap.putIfAbsent(q.blockId, () => []).add(q);
    }

    final List<BlockStat> stats = [];
    final sortedBlockIds = blockMap.keys.toList()..sort();

    for (final bId in sortedBlockIds) {
      final questions = blockMap[bId]!;
      final title = questions.first.blockName.getText(langCode);
      final wrongCount = questions.where((q) => wrongIds.contains(q.id)).length;

      stats.add(
        BlockStat(
          blockId: bId,
          blockTitle: title,
          totalQuestions: questions.length,
          wrongQuestions: wrongCount,
        ),
      );
    }

    return stats;
  }
}
