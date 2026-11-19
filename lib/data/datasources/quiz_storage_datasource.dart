import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_result_model.dart';
import 'auth_storage_datasource.dart';

class QuizStorageDataSource {
  static const String _wrongQuestionsKey = 'wrong_question_ids';
  static const String _bookmarkedQuestionsKey = 'bookmarked_question_ids';
  static const String _quizHistoryKey = 'quiz_history';

  Future<String> _getScopedKey(String baseKey) async {
    final user = await AuthStorageDataSource().getCurrentUser();
    if (user != null && user.id.isNotEmpty) {
      return '${baseKey}_${user.id}';
    }
    return baseKey;
  }

  Future<List<String>> getWrongQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_wrongQuestionsKey);
    return prefs.getStringList(key) ?? [];
  }

  Future<void> saveWrongQuestion(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_wrongQuestionsKey);
    final list = prefs.getStringList(key) ?? [];
    if (!list.contains(questionId)) {
      list.add(questionId);
      await prefs.setStringList(key, list);
    }
  }

  Future<void> removeWrongQuestion(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_wrongQuestionsKey);
    final list = prefs.getStringList(key) ?? [];
    if (list.remove(questionId)) {
      await prefs.setStringList(key, list);
    }
  }

  Future<List<String>> getBookmarkedQuestionIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_bookmarkedQuestionsKey);
    return prefs.getStringList(key) ?? [];
  }

  Future<void> saveBookmarkedQuestion(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_bookmarkedQuestionsKey);
    final list = prefs.getStringList(key) ?? [];
    if (!list.contains(questionId)) {
      list.add(questionId);
      await prefs.setStringList(key, list);
    }
  }

  Future<void> removeBookmarkedQuestion(String questionId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_bookmarkedQuestionsKey);
    final list = prefs.getStringList(key) ?? [];
    if (list.remove(questionId)) {
      await prefs.setStringList(key, list);
    }
  }

  Future<List<QuizResultModel>> getQuizHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_quizHistoryKey);
    final stringList = prefs.getStringList(key) ?? [];
    return stringList
        .map((str) => QuizResultModel.fromJson(jsonDecode(str) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveQuizResult(QuizResultModel result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getScopedKey(_quizHistoryKey);
    final stringList = prefs.getStringList(key) ?? [];
    stringList.add(jsonEncode(result.toJson()));
    await prefs.setStringList(key, stringList);
  }
}
