import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question_model.dart';

class QuizLocalDataSource {
  final String assetPath;
  List<QuestionModel>? _cache;

  QuizLocalDataSource({this.assetPath = 'assets/data/questions.json'});

  Future<List<QuestionModel>> loadQuestionsFromAsset() async {
    if (_cache != null) {
      return _cache!;
    }
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is List) {
        _cache = List<QuestionModel>.unmodifiable(
          decoded
              .map((item) => QuestionModel.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
        return _cache!;
      } else {
        throw const FormatException('Invalid JSON format: expected list');
      }
    } catch (e) {
      throw Exception('Không thể tải ngân hàng câu hỏi: $e');
    }
  }

  void clearCache() {
    _cache = null;
  }
}
