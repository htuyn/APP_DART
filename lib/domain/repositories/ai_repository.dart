import '../../data/models/question_model.dart';

abstract class IAiRepository {
  Future<String> getExplanation({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    String action = 'explain',
  });
}
