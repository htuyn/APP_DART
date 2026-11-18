import 'question_model.dart';
import 'quiz_result_model.dart';

/// Thống kê số câu đúng/sai theo khối, dùng dữ liệu câu hỏi và sổ câu sai.
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

  /// Giữ cách tính hiện tại: câu trong ngân hàng không nằm trong sổ sai được tính đúng.
  int get correctCount =>
      (totalQuestions - wrongQuestions).clamp(0, totalQuestions).toInt();

  double get accuracyRate =>
      totalQuestions <= 0 ? 0.0 : (correctCount / totalQuestions) * 100.0;

  /// Tạo thống kê cho một khối; các câu hỏi rỗng vẫn trả về một thống kê hợp lệ.
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

/// Tổng hợp lịch sử thi; không thay đổi cấu trúc lưu của từng kết quả.
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
