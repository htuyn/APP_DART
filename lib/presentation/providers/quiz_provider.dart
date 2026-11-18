import 'package:flutter/foundation.dart';
import '../../data/models/question_model.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'course_progress_provider.dart';
import 'gamification_provider.dart';

enum QuizLoadingState { initial, loading, loaded, error }

class QuizProvider with ChangeNotifier {
  final IQuizRepository repository;
  final GamificationProvider? gamificationProvider;
  final CourseProgressProvider? courseProgressProvider;

  QuizLoadingState _state = QuizLoadingState.initial;
  String? _errorMessage;
  List<QuestionModel> _allQuestions = [];
  Set<String> _wrongQuestionIds = {};
  Set<String> _bookmarkedQuestionIds = {};

  QuizLoadingState get state => _state;
  String? get errorMessage => _errorMessage;
  List<QuestionModel> get allQuestions => _allQuestions;
  Set<String> get wrongQuestionIds => _wrongQuestionIds;
  Set<String> get bookmarkedQuestionIds => _bookmarkedQuestionIds;

  List<QuestionModel> get wrongQuestions =>
      _allQuestions.where((q) => _wrongQuestionIds.contains(q.id)).toList();

  List<QuestionModel> get bookmarkedQuestions =>
      _allQuestions.where((q) => _bookmarkedQuestionIds.contains(q.id)).toList();

  bool isBookmarked(String questionId) => _bookmarkedQuestionIds.contains(questionId);

  QuizProvider({
    required this.repository,
    this.gamificationProvider,
    this.courseProgressProvider,
  });

  Future<void> initialize() async {
    _state = QuizLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _allQuestions = await repository.loadQuestions();
      final wrongList = await repository.getWrongQuestionIds();
      _wrongQuestionIds = wrongList.toSet();
      final bookmarkedList = await repository.getBookmarkedQuestionIds();
      _bookmarkedQuestionIds = bookmarkedList.toSet();
      _state = QuizLoadingState.loaded;
    } catch (e) {
      _state = QuizLoadingState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> reloadProgress() async {
    final wrongList = await repository.getWrongQuestionIds();
    _wrongQuestionIds = wrongList.toSet();
    final bookmarkedList = await repository.getBookmarkedQuestionIds();
    _bookmarkedQuestionIds = bookmarkedList.toSet();
    notifyListeners();
  }

  Future<void> toggleBookmark(String questionId) async {
    if (_bookmarkedQuestionIds.contains(questionId)) {
      _bookmarkedQuestionIds.remove(questionId);
      await repository.removeBookmarkedQuestion(questionId);
    } else {
      _bookmarkedQuestionIds.add(questionId);
      await repository.saveBookmarkedQuestion(questionId);
    }
    notifyListeners();
  }

  List<QuestionModel> getQuestionsByBlock(int blockId) {
    if (blockId == 0) return _allQuestions;
    return _allQuestions.where((q) => q.blockId == blockId).toList();
  }

  Map<int, List<QuestionModel>> get groupedByBlock {
    final Map<int, List<QuestionModel>> map = {};
    for (final q in _allQuestions) {
      map.putIfAbsent(q.blockId, () => []).add(q);
    }
    return map;
  }

  Future<void> recordAnswer({
    required QuestionModel question,
    required bool isCorrect,
  }) async {
    if (!isCorrect) {
      _wrongQuestionIds.add(question.id);
      await repository.saveWrongQuestion(question.id);
    } else {
      if (_wrongQuestionIds.contains(question.id)) {
        _wrongQuestionIds.remove(question.id);
        await repository.removeWrongQuestion(question.id);
      }
    }
    // Record each practice answer without changing the existing wrong-book flow.
    final gamification = gamificationProvider;
    if (gamification != null) {
      await gamification.ghiNhanTraLoi(isCorrect: isCorrect);
    }
    await courseProgressProvider?.recordPracticeAnswer(
      questionId: question.id,
      isCorrect: isCorrect,
    );
    notifyListeners();
  }
}
