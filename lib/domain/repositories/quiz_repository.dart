import '../../data/models/question_model.dart';
import '../../data/models/quiz_result_model.dart';

abstract class IQuizRepository {
  Future<List<QuestionModel>> loadQuestions();
  Future<List<String>> getWrongQuestionIds();
  Future<void> saveWrongQuestion(String questionId);
  Future<void> removeWrongQuestion(String questionId);
  Future<List<QuizResultModel>> getQuizHistory();
  Future<void> saveQuizResult(QuizResultModel result);
}
