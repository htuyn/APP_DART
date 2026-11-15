import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/question_model.dart';
import '../../data/models/quiz_result_model.dart';
import '../../domain/repositories/quiz_repository.dart';

class ExamProvider with ChangeNotifier {
  final IQuizRepository repository;

  List<QuestionModel> _examQuestions = [];
  final Map<int, int> _userAnswers = {}; // questionIndex -> selectedOptionIndex
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalDurationSeconds = 0;
  bool _isSubmitted = false;
  QuizResultModel? _lastResult;

  List<QuestionModel> get examQuestions => _examQuestions;
  Map<int, int> get userAnswers => _userAnswers;
  int get remainingSeconds => _remainingSeconds;
  int get totalDurationSeconds => _totalDurationSeconds;
  bool get isSubmitted => _isSubmitted;
  QuizResultModel? get lastResult => _lastResult;

  int get timeSpentSeconds => _totalDurationSeconds - _remainingSeconds;

  ExamProvider({required this.repository});

  void startExam({
    required List<QuestionModel> allQuestions,
    int numberOfQuestions = 20,
    int durationMinutes = 15,
  }) {
    _timer?.cancel();
    _userAnswers.clear();
    _isSubmitted = false;
    _lastResult = null;

    final shuffled = List<QuestionModel>.from(allQuestions)..shuffle();
    _examQuestions = shuffled.take(numberOfQuestions).toList();

    _totalDurationSeconds = durationMinutes * 60;
    _remainingSeconds = _totalDurationSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        submitExam();
      }
    });

    notifyListeners();
  }

  void selectAnswer(int questionIndex, int optionIndex) {
    if (_isSubmitted) return;
    _userAnswers[questionIndex] = optionIndex;
    notifyListeners();
  }

  Future<QuizResultModel> submitExam() async {
    if (_isSubmitted && _lastResult != null) return _lastResult!;

    _timer?.cancel();
    _timer = null;
    _isSubmitted = true;

    int correctCount = 0;
    final List<String> wrongIds = [];

    for (int i = 0; i < _examQuestions.length; i++) {
      final q = _examQuestions[i];
      final selected = _userAnswers[i];
      if (selected == q.correctIndex) {
        correctCount++;
        // If it was previously wrong and now right, remove it
        await repository.removeWrongQuestion(q.id);
      } else {
        wrongIds.add(q.id);
        await repository.saveWrongQuestion(q.id);
      }
    }

    final result = QuizResultModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      score: correctCount,
      totalQuestions: _examQuestions.length,
      timeSpentSeconds: timeSpentSeconds,
      wrongQuestionIds: wrongIds,
    );

    _lastResult = result;
    await repository.saveQuizResult(result);
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
