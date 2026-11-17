import 'package:shared_preferences/shared_preferences.dart';

class CourseProgressStorageDataSource {
  static const String _practiceAnswerCountKey = 'course_practice_answer_count_v1';
  static const String _practiceCorrectCountKey =
      'course_practice_correct_count_v1';
  static const String _attemptedQuestionIdsKey =
      'course_attempted_question_ids_v1';
  static const String _masteredQuestionIdsKey =
      'course_mastered_question_ids_v1';

  Future<void> recordPracticeAnswer({
    required String questionId,
    required bool isCorrect,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final answerCount = preferences.getInt(_practiceAnswerCountKey) ?? 0;
    await preferences.setInt(_practiceAnswerCountKey, answerCount + 1);

    final correctCount = preferences.getInt(_practiceCorrectCountKey) ?? 0;
    if (isCorrect) {
      await preferences.setInt(_practiceCorrectCountKey, correctCount + 1);
    }

    final attemptedIds =
        preferences.getStringList(_attemptedQuestionIdsKey) ?? <String>[];
    if (!attemptedIds.contains(questionId)) {
      attemptedIds.add(questionId);
      await preferences.setStringList(_attemptedQuestionIdsKey, attemptedIds);
    }

    final masteredIds =
        preferences.getStringList(_masteredQuestionIdsKey) ?? <String>[];
    if (isCorrect && !masteredIds.contains(questionId)) {
      masteredIds.add(questionId);
      await preferences.setStringList(_masteredQuestionIdsKey, masteredIds);
    } else if (!isCorrect && masteredIds.remove(questionId)) {
      await preferences.setStringList(_masteredQuestionIdsKey, masteredIds);
    }
  }

  Future<PracticeProgressSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    return PracticeProgressSnapshot(
      answerCount: preferences.getInt(_practiceAnswerCountKey) ?? 0,
      correctAnswerCount: preferences.getInt(_practiceCorrectCountKey) ?? 0,
      attemptedQuestionIds:
          (preferences.getStringList(_attemptedQuestionIdsKey) ?? const [])
              .toSet(),
      masteredQuestionIds:
          (preferences.getStringList(_masteredQuestionIdsKey) ?? const [])
              .toSet(),
    );
  }
}

class PracticeProgressSnapshot {
  PracticeProgressSnapshot({
    required this.answerCount,
    required this.correctAnswerCount,
    required Set<String> attemptedQuestionIds,
    required Set<String> masteredQuestionIds,
  }) : attemptedQuestionIds = Set.unmodifiable(attemptedQuestionIds),
       masteredQuestionIds = Set.unmodifiable(masteredQuestionIds);

  final int answerCount;
  final int correctAnswerCount;
  final Set<String> attemptedQuestionIds;
  final Set<String> masteredQuestionIds;
}
