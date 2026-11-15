import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_result_model.dart';

class QuizStorageDataSource {
  static const String _wrongQuestionsKey = 'wrong_question_ids';
  static const String _quizHistoryKey = 'quiz_history';

  Future<List<String>> getWrongQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_wrongQuestionsKey) ?? [];
  }

  Future<void> saveWrongQuestion(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_wrongQuestionsKey) ?? [];
    if (!list.contains(questionId)) {
      list.add(questionId);
      await prefs.setStringList(_wrongQuestionsKey, list);
    }
  }

  Future<void> removeWrongQuestion(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_wrongQuestionsKey) ?? [];
    if (list.remove(questionId)) {
      await prefs.setStringList(_wrongQuestionsKey, list);
    }
  }

  Future<List<QuizResultModel>> getQuizHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(_quizHistoryKey) ?? [];
    return stringList
        .map((str) => QuizResultModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveQuizResult(QuizResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(_quizHistoryKey) ?? [];
    stringList.add(jsonEncode(result.toJson()));
    await prefs.setStringList(_quizHistoryKey, stringList);
  }
}
