import 'package:flutter/foundation.dart';
import '../../data/models/question_model.dart';
import '../../data/models/quiz_result_model.dart';
import '../../data/models/thong_ke.dart';
import '../../domain/repositories/quiz_repository.dart';

// Preserve the existing test/UI import path after moving the model.
export '../../data/models/thong_ke.dart' show BlockStat;

// BlockStat Ä‘Æ°á»£c Ä‘á»‹nh nghÄ©a trong data/models/thong_ke.dart Ä‘á»ƒ tÃ¡i sá»­ dá»¥ng.

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
      // DÃ¹ng factory chung cá»§a model; cÃ¡ch Ä‘áº¿m cÃ¢u sai theo wrongIds Ä‘Æ°á»£c giá»¯ nguyÃªn.
      stats.add(
        BlockStat.fromQuestions(
          blockId: bId,
          questions: questions,
          wrongIds: wrongIds,
          langCode: langCode,
        ),
      );
    }

    return stats;
  }
}
