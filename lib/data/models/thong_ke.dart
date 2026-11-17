import 'question_model.dart';
import 'quiz_result_model.dart';

/// Thá»‘ng kÃª sá»‘ cÃ¢u Ä‘Ãºng/sai theo khá»‘i, dÃ¹ng dá»¯ liá»‡u cÃ¢u há»i vÃ  sá»• cÃ¢u sai.
class BlockStat {
  final int blockId;
  final String blockTitle;
  final int totalQuestions;
  final int wrongQuestions;

  const BlockStat({
    required this.blockId,
    required this.blockTitle,
    required this.totalQuestions,
    required this.wrongQuestions,
  });

  /// Giá»¯ cÃ¡ch tÃ­nh hiá»‡n táº¡i: cÃ¢u trong ngÃ¢n hÃ ng khÃ´ng náº±m trong sá»• sai Ä‘Æ°á»£c tÃ­nh Ä‘Ãºng.
  int get correctCount =>
      (totalQuestions - wrongQuestions).clamp(0, totalQuestions).toInt();

  double get accuracyRate =>
      totalQuestions <= 0 ? 0.0 : (correctCount / totalQuestions) * 100.0;

  /// Táº¡o thá»‘ng kÃª cho má»™t khá»‘i; cÃ¡c cÃ¢u há»i rá»—ng váº«n tráº£ vá» má»™t thá»‘ng kÃª há»£p lá»‡.
  factory BlockStat.fromQuestions({
    required int blockId,
    required List<QuestionModel> questions,
    required Set<String> wrongIds,
    required String langCode,
  }) {
    final title = questions.isEmpty
        ? 'Block $blockId'
        : questions.first.blockName.getText(langCode);
    final wrongCount =
        questions.where((question) => wrongIds.contains(question.id)).length;

    return BlockStat(
      blockId: blockId,
      blockTitle: title,
      totalQuestions: questions.length,
      wrongQuestions: wrongCount,
    );
  }
}

/// Tá»•ng há»£p lá»‹ch sá»­ thi; khÃ´ng thay Ä‘á»•i cáº¥u trÃºc lÆ°u cá»§a tá»«ng káº¿t quáº£.
class QuizHistorySummary {
  final int attemptCount;
  final int totalQuestions;
  final int totalCorrectAnswers;
  final int totalTimeSpentSeconds;
  final double averagePercentage;
  final double bestPercentage;

  const QuizHistorySummary({
    required this.attemptCount,
    required this.totalQuestions,
    required this.totalCorrectAnswers,
    required this.totalTimeSpentSeconds,
    required this.averagePercentage,
    required this.bestPercentage,
  });

  factory QuizHistorySummary.fromResults(Iterable<QuizResultModel> results) {
    var attempts = 0;
    var questions = 0;
    var correctAnswers = 0;
    var timeSpent = 0;
    var percentageSum = 0.0;
    var best = 0.0;

    for (final result in results) {
      attempts++;
      questions += result.totalQuestions;
      correctAnswers += result.score;
      timeSpent += result.timeSpentSeconds;
      percentageSum += result.percentage;
      if (result.percentage > best) best = result.percentage;
    }

    return QuizHistorySummary(
      attemptCount: attempts,
      totalQuestions: questions,
      totalCorrectAnswers: correctAnswers,
      totalTimeSpentSeconds: timeSpent,
      averagePercentage: attempts == 0 ? 0.0 : percentageSum / attempts,
      bestPercentage: best,
    );
  }
}
