/// Progress values supplied by the existing quiz/course state at evaluation time.
///
/// Practice-only counts and overall accuracy must be populated from separately
/// classified attempts; generic quiz history cannot distinguish those classes.
class CourseProgressModel {
  CourseProgressModel({
    required Set<int> allBlockIds,
    required Set<int> completedBlockIds,
    required this.totalQuestionsInBank,
    required this.practiceQuestionsAnswered,
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.capstoneExamScore,
    required this.capstoneExamTotal,
  }) : allBlockIds = Set.unmodifiable(allBlockIds),
       completedBlockIds = Set.unmodifiable(completedBlockIds);

  final Set<int> allBlockIds;
  final Set<int> completedBlockIds;

  /// Number of questions currently available in the loaded question bank.
  final int totalQuestionsInBank;

  /// Number of answered questions from practice sessions, counted by the course source.
  final int practiceQuestionsAnswered;

  /// Correct and answered question totals used for overall accuracy.
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;

  final int? capstoneExamScore;
  final int? capstoneExamTotal;

  /// Practice threshold is 90% of the loaded bank, rounded up and never below 1.
  int get requiredPracticeQuestions {
    final required = (totalQuestionsInBank * 0.9).ceil();
    return required < 1 ? 1 : required;
  }

  bool get allBlocksCompleted =>
      allBlockIds.isNotEmpty && allBlockIds.difference(completedBlockIds).isEmpty;

  double get overallAccuracyPercent => totalQuestionsAnswered <= 0
      ? 0
      : totalCorrectAnswers * 100 / totalQuestionsAnswered;

  double? get capstonePercentage {
    final total = capstoneExamTotal;
    final score = capstoneExamScore;
    if (total == null || score == null || total <= 0) return null;
    return score * 100 / total;
  }

  Map<String, dynamic> toJson() => {
    'all_block_ids': allBlockIds.toList()..sort(),
    'completed_block_ids': completedBlockIds.toList()..sort(),
    'total_questions_in_bank': totalQuestionsInBank,
    'practice_questions_answered': practiceQuestionsAnswered,
    'total_questions_answered': totalQuestionsAnswered,
    'total_correct_answers': totalCorrectAnswers,
    'capstone_exam_score': capstoneExamScore,
    'capstone_exam_total': capstoneExamTotal,
  };

  factory CourseProgressModel.fromJson(Map<String, dynamic> json) {
    Set<int> readIds(String key) {
      final raw = json[key];
      if (raw is! List) return <int>{};
      return raw.whereType<num>().map((value) => value.toInt()).toSet();
    }

    int readInt(String key) {
      final value = json[key];
      return value is num ? value.toInt() : 0;
    }

    int? readNullableInt(String key) {
      final value = json[key];
      return value is num ? value.toInt() : null;
    }

    return CourseProgressModel(
      allBlockIds: readIds('all_block_ids'),
      completedBlockIds: readIds('completed_block_ids'),
      totalQuestionsInBank: readInt('total_questions_in_bank'),
      practiceQuestionsAnswered: readInt('practice_questions_answered'),
      totalQuestionsAnswered: readInt('total_questions_answered'),
      totalCorrectAnswers: readInt('total_correct_answers'),
      capstoneExamScore: readNullableInt('capstone_exam_score'),
      capstoneExamTotal: readNullableInt('capstone_exam_total'),
    );
  }
}
