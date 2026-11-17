import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/models/question_model.dart';
import '../../data/models/quiz_result_model.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'course_progress_provider.dart';
import 'gamification_provider.dart';

class ExamProvider with ChangeNotifier {
  static const int paperCount = 10;
  static const int paperSize = 30;
  static const int paperMinutes = 40;

  final IQuizRepository repository;
  final GamificationProvider? gamificationProvider;
  final CourseProgressProvider? courseProgressProvider;

  List<QuestionModel> _examQuestions = [];
  final Map<int, int> _userAnswers = {};
  final Set<int> _flagged = {};
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalDurationSeconds = 0;
  bool _isSubmitted = false;
  bool _isCapstoneExam = false;
  int? _paperIndex;
  QuizResultModel? _lastResult;

  List<QuestionModel> get examQuestions => _examQuestions;
  Map<int, int> get userAnswers => _userAnswers;
  Set<int> get flagged => _flagged;
  int get remainingSeconds => _remainingSeconds;
  int get totalDurationSeconds => _totalDurationSeconds;
  bool get isSubmitted => _isSubmitted;
  bool get isCapstoneExam => _isCapstoneExam;
  int? get paperIndex => _paperIndex;
  QuizResultModel? get lastResult => _lastResult;
  int get answeredCount => _userAnswers.length;
  int get timeSpentSeconds => _totalDurationSeconds - _remainingSeconds;

  ExamProvider({
    required this.repository,
    this.gamificationProvider,
    this.courseProgressProvider,
  });

  static List<QuestionModel> questionsForPaper(
    List<QuestionModel> allQuestions,
    int paperIndex, {
    int size = paperSize,
  }) {
    if (allQuestions.isEmpty || size <= 0) return const [];
    final pool = List<QuestionModel>.from(allQuestions)
      ..sort((a, b) => a.id.compareTo(b.id));
    pool.shuffle(Random(42));
    if (pool.length <= size) return pool;
    final index = (paperIndex - 1).clamp(0, paperCount - 1);
    final start = (index * size) % pool.length;
    return List<QuestionModel>.generate(
      size,
      (offset) => pool[(start + offset) % pool.length],
    );
  }

  void startExam({
    required List<QuestionModel> allQuestions,
    int numberOfQuestions = 20,
    int durationMinutes = 15,
    int? paperIndex,
    bool isCapstoneExam = false,
  }) {
    _timer?.cancel();
    _userAnswers.clear();
    _flagged.clear();
    _isSubmitted = false;
    _isCapstoneExam = isCapstoneExam;
    _lastResult = null;
    _paperIndex = paperIndex;

    if (paperIndex != null) {
      _examQuestions = questionsForPaper(
        allQuestions,
        paperIndex,
        size: numberOfQuestions,
      );
    } else {
      final shuffled = List<QuestionModel>.from(allQuestions)..shuffle();
      _examQuestions = shuffled.take(numberOfQuestions).toList();
    }

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
    // Record the study interaction now; answer XP is awarded with final scores.
    final gamification = gamificationProvider;
    if (gamification != null) unawaited(gamification.ghiNhanTraLoi());
    notifyListeners();
  }

  void toggleFlag(int questionIndex) {
    if (_isSubmitted) return;
    if (_flagged.contains(questionIndex)) {
      _flagged.remove(questionIndex);
    } else {
      _flagged.add(questionIndex);
    }
    notifyListeners();
  }

  void abandonExam() {
    _timer?.cancel();
    _timer = null;
    _userAnswers.clear();
    _flagged.clear();
    _examQuestions = [];
    _isSubmitted = false;
    _isCapstoneExam = isCapstoneExam;
    _lastResult = null;
    _paperIndex = null;
    _remainingSeconds = 0;
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
      isCapstoneExam: _isCapstoneExam,
    );

    _lastResult = result;
    await repository.saveQuizResult(result);
    await courseProgressProvider?.refresh();
    // Record the completed attempt and perfect-score badge eligibility.
    final gamification = gamificationProvider;
    if (gamification != null) {
      await gamification.ghiNhanBaiThi(
        correctCount,
        _examQuestions.length,
        answeredCount: _userAnswers.length,
      );
    }
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
