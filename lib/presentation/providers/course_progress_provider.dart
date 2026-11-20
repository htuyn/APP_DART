import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/datasources/course_progress_storage_datasource.dart';
import '../../data/models/course_progress_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/quiz_result_model.dart';
import '../../domain/blockchain/certificate_eligibility_engine.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'stats_provider.dart';

class CourseProgressProvider extends ChangeNotifier {
  CourseProgressProvider({
    required this.repository,
    required this.statsProvider,
    CourseProgressStorageDataSource? storage,
    this.eligibilityEngine = const CertificateEligibilityEngine(),
  }) : _storage = storage ?? CourseProgressStorageDataSource();

  final IQuizRepository repository;
  final StatsProvider statsProvider;
  final CertificateEligibilityEngine eligibilityEngine;
  final CourseProgressStorageDataSource _storage;

  CourseProgressModel _progress = CourseProgressModel(
    allBlockIds: const {},
    completedBlockIds: const {},
    totalQuestionsInBank: 0,
    practiceQuestionsAnswered: 0,
    totalQuestionsAnswered: 0,
    totalCorrectAnswers: 0,
    capstoneExamScore: null,
    capstoneExamTotal: null,
  );
  List<QuestionModel> _questions = const [];
  List<QuizResultModel> _history = const [];
  List<int> _cachedAllBlockIds = const [];
  bool _isLoading = false;
  String? _errorMessage;
  Future<void>? _refreshFuture;
  Future<void> _recordQueue = Future<void>.value();

  CourseProgressModel get progress => _progress;
  List<QuestionModel> get questions => List.unmodifiable(_questions);
  List<QuizResultModel> get quizHistory => List.unmodifiable(_history);
  List<int> get allBlockIds {
    if (_cachedAllBlockIds.isEmpty && _questions.isNotEmpty) {
      final ids = _questions.map((question) => question.blockId).toSet().toList()
        ..sort();
      _cachedAllBlockIds = List.unmodifiable(ids);
    }
    return _cachedAllBlockIds;
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get practiceQuestionsAnswered => _progress.practiceQuestionsAnswered;
  int get totalQuestionsInBank => _progress.totalQuestionsInBank;
  int get requiredPracticeQuestions => _progress.requiredPracticeQuestions;
  int get completedBlockCount => _progress.completedBlockIds.length;
  int get totalBlockCount => _progress.allBlockIds.length;
  double get overallAccuracyPercent => _progress.overallAccuracyPercent;
  int? get capstoneExamScore => _progress.capstoneExamScore;
  int? get capstoneExamTotal => _progress.capstoneExamTotal;

  CertificateEligibility get certificateEligibility =>
      eligibilityEngine.evaluateCourseCompletion(progress: _progress);

  Future<void> initialize() => refresh();

  Future<void> refresh() {
    final current = _refreshFuture;
    if (current != null) return current;

    final refreshFuture = _loadProgress();
    _refreshFuture = refreshFuture;
    return refreshFuture.whenComplete(() => _refreshFuture = null);
  }

  /// Called by QuizProvider for practice answers. It only updates local progress.
  Future<void> recordPracticeAnswer({
    required String questionId,
    required bool isCorrect,
  }) {
    final completer = Completer<void>();
    _recordQueue = _recordQueue.then((_) async {
      try {
        final inFlightRefresh = _refreshFuture;
        if (inFlightRefresh != null) {
          await inFlightRefresh;
          if (identical(_refreshFuture, inFlightRefresh)) {
            _refreshFuture = null;
          }
        }
        await _storage.recordPracticeAnswer(
          questionId: questionId,
          isCorrect: isCorrect,
        );
        await refresh();
      } catch (error) {
        _errorMessage = error.toString();
        notifyListeners();
      }
      completer.complete();
    });
    return completer.future;
  }

  Future<void> _loadProgress() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        repository.loadQuestions(),
        repository.getWrongQuestionIds(),
        statsProvider.loadHistory(),
        _storage.load(),
      ]);
      _questions = results[0] as List<QuestionModel>;
      final wrongIds = (results[1] as List<String>).toSet();
      final practice = results[3] as PracticeProgressSnapshot;
      final history = List<QuizResultModel>.of(statsProvider.history);
      _history = List.unmodifiable(history);

      final stats = statsProvider.calculateBlockStats(
        allQuestions: _questions,
        wrongIds: wrongIds,
        langCode: 'vi',
      );
      final questionsByBlock = <int, List<QuestionModel>>{};
      for (final question in _questions) {
        questionsByBlock.putIfAbsent(question.blockId, () => []).add(question);
      }
      final completedBlocks = <int>{};
      for (final stat in stats) {
        final blockQuestions = questionsByBlock[stat.blockId] ?? const [];
        final allQuestionsMastered = blockQuestions.isNotEmpty &&
            blockQuestions.every(
              (question) =>
                  practice.masteredQuestionIds.contains(question.id),
            );
        if (stat.wrongQuestions == 0 && allQuestionsMastered) {
          completedBlocks.add(stat.blockId);
        }
      }

      final capstoneAttempts = history
          .where((result) => result.isCapstoneExam)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestCapstone =
          capstoneAttempts.isEmpty ? null : capstoneAttempts.first;
      final examQuestionCount = history.fold<int>(
        0,
        (total, result) => total + result.totalQuestions,
      );
      final examCorrectCount = history.fold<int>(
        0,
        (total, result) => total + result.score,
      );

      _progress = CourseProgressModel(
        allBlockIds: _questions.map((question) => question.blockId).toSet(),
        totalQuestionsInBank: _questions.length,
        completedBlockIds: completedBlocks,
        practiceQuestionsAnswered: practice.answerCount,
        totalQuestionsAnswered: practice.answerCount + examQuestionCount,
        totalCorrectAnswers: practice.correctAnswerCount + examCorrectCount,
        capstoneExamScore: latestCapstone?.score,
        capstoneExamTotal: latestCapstone?.totalQuestions,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
