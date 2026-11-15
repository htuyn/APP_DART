import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_local_datasource.dart';
import '../datasources/quiz_storage_datasource.dart';
import '../models/question_model.dart';
import '../models/quiz_result_model.dart';

class QuizRepositoryImpl implements IQuizRepository {
  final QuizLocalDataSource localDataSource;
  final QuizStorageDataSource storageDataSource;

  QuizRepositoryImpl({
    required this.localDataSource,
    required this.storageDataSource,
  });

  @override
  Future<List<QuestionModel>> loadQuestions() {
    return localDataSource.loadQuestionsFromAsset();
  }

  @override
  Future<List<String>> getWrongQuestionIds() {
    return storageDataSource.getWrongQuestionIds();
  }

  @override
  Future<void> saveWrongQuestion(String questionId) {
    return storageDataSource.saveWrongQuestion(questionId);
  }

  @override
  Future<void> removeWrongQuestion(String questionId) {
    return storageDataSource.removeWrongQuestion(questionId);
  }

  @override
  Future<List<QuizResultModel>> getQuizHistory() {
    return storageDataSource.getQuizHistory();
  }

  @override
  Future<void> saveQuizResult(QuizResultModel result) {
    return storageDataSource.saveQuizResult(result);
  }
}
