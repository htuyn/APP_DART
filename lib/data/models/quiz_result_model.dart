class QuizResultModel {
  final String id;
  final DateTime timestamp;
  final int score;
  final int totalQuestions;
  final int timeSpentSeconds;
  final List<String> wrongQuestionIds;
  final bool isCapstoneExam;

  const QuizResultModel({
    required this.id,
    required this.timestamp,
    required this.score,
    required this.totalQuestions,
    required this.timeSpentSeconds,
    required this.wrongQuestionIds,
    this.isCapstoneExam = false,
  });

  double get percentage =>
      totalQuestions == 0 ? 0.0 : (score / totalQuestions) * 100.0;

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      score: json['score'] as int,
      totalQuestions: json['total_questions'] as int,
      timeSpentSeconds: json['time_spent_seconds'] as int,
      wrongQuestionIds: List<String>.from(json['wrong_question_ids'] ?? []),
      isCapstoneExam: json['is_capstone_exam'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'score': score,
      'total_questions': totalQuestions,
      'time_spent_seconds': timeSpentSeconds,
      'wrong_question_ids': wrongQuestionIds,
      'is_capstone_exam': isCapstoneExam,
    };
  }
}
