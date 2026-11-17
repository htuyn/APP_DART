import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question_model.dart';

class QuizLocalDataSource {
  final String assetPath;

  QuizLocalDataSource({this.assetPath = 'assets/data/questions.json'});

  Future<List<QuestionModel>> loadQuestionsFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is List) {
        return decoded
            .map((item) => QuestionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw const FormatException('Invalid JSON format: expected list');
      }
    } catch (e) {
      throw Exception('KhÃ´ng thá»ƒ táº£i ngÃ¢n hÃ ng cÃ¢u há»i: $e');
    }
  }
}
