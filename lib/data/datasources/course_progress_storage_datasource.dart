import 'package:shared_preferences/shared_preferences.dart';
import 'auth_storage_datasource.dart';

class CourseProgressStorageDataSource {
  static const String _practiceAnswerCountKey = 'course_practice_answer_count_v1';
  static const String _practiceCorrectCountKey =
      'course_practice_correct_count_v1';
  static const String _attemptedQuestionIdsKey =
      'course_attempted_question_ids_v1';
  static const String _masteredQuestionIdsKey =
      'course_mastered_question_ids_v1';

  Future<String> _getScopedKey(String baseKey) async {
    final user = await AuthStorageDataSource().getCurrentUser();
    if (user != null && user.id.isNotEmpty) {
      return '${baseKey}_${user.id}';
    }
    return baseKey;
  }

  Future<void> recordPracticeAnswer({
    required String questionId,
    required bool isCorrect,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final answerKey = await _getScopedKey(_practiceAnswerCountKey);
    final correctKey = await _getScopedKey(_practiceCorrectCountKey);
    final attemptedKey = await _getScopedKey(_attemptedQuestionIdsKey);
    final masteredKey = await _getScopedKey(_masteredQuestionIdsKey);

    final answerCount = preferences.getInt(answerKey) ?? 0;
    await preferences.setInt(answerKey, answerCount + 1);

    final correctCount = preferences.getInt(correctKey) ?? 0;
    if (isCorrect) {
      await preferences.setInt(correctKey, correctCount + 1);
    }

    final attemptedIds =
        preferences.getStringList(attemptedKey) ?? <String>[];
    if (!attemptedIds.contains(questionId)) {
      attemptedIds.add(questionId);
      await preferences.setStringList(attemptedKey, attemptedIds);
    }

    final masteredIds =
        preferences.getStringList(masteredKey) ?? <String>[];
    if (isCorrect && !masteredIds.contains(questionId)) {
      masteredIds.add(questionId);
      await preferences.setStringList(masteredKey, masteredIds);
    } else if (!isCorrect && masteredIds.remove(questionId)) {
      await preferences.setStringList(masteredKey, masteredIds);
    }
  }

  Future<PracticeProgressSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final answerKey = await _getScopedKey(_practiceAnswerCountKey);
    final correctKey = await _getScopedKey(_practiceCorrectCountKey);
    final attemptedKey = await _getScopedKey(_attemptedQuestionIdsKey);
    final masteredKey = await _getScopedKey(_masteredQuestionIdsKey);

    return PracticeProgressSnapshot(
      answerCount: preferences.getInt(answerKey) ?? 0,
      correctAnswerCount: preferences.getInt(correctKey) ?? 0,
      attemptedQuestionIds:
          (preferences.getStringList(attemptedKey) ?? const [])
              .toSet(),
      masteredQuestionIds:
          (preferences.getStringList(masteredKey) ?? const [])
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
