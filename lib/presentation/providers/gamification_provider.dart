import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/clock.dart';
import '../../data/models/gamification_model.dart';
import '../../data/models/question_model.dart';
import '../../domain/gamification/badge_catalog.dart';
import '../../domain/gamification/gamification_engine.dart';
import '../../domain/repositories/i_gamification_repository.dart';

/// ChangeNotifier adapter matching the Provider-based state management already
/// used by the app's quiz, exam, language, and statistics providers.
class GamificationProvider extends ChangeNotifier {
  GamificationProvider({
    required IGamificationRepository repository,
    Clock clock = const SystemClock(),
  }) : _repository = repository,
       _engine = GamificationEngine(repository: repository, clock: clock);

  final IGamificationRepository _repository;
  final GamificationEngine _engine;

  GamificationModel _progress = GamificationModel();
  bool _isLoading = false;
  String? _errorMessage;
  List<BadgeDefinition> _newBadges = const [];
  Future<void> _actionQueue = Future<void>.value();
  int _revision = 0;
  bool _disposed = false;

  GamificationModel get progress => _progress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentStreak => _engine.streakHienThi(_progress);
  LevelProgress get levelProgress => _engine.levelProgressFor(_progress.xp);
  List<BadgeDefinition> get badges => BadgeCatalog.all;
  List<BadgeDefinition> get newlyUnlockedBadges =>
      List.unmodifiable(_newBadges);
  bool get dailyChallengeCompleted =>
      _progress.completedDailyChallengeDateKey == _engine.todayDateKey;
  List<QuestionModel> dailyChallengeQuestions(List<QuestionModel> questions) =>
      _engine.dailyChallengeQuestions(questions);

  Future<void> initialize() async {
    final revision = _revision;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _engine.refreshForToday();
      if (!_disposed && revision == _revision) _progress = loaded;
    } catch (error) {
      if (!_disposed && revision == _revision) {
        _errorMessage = error.toString();
      }
    } finally {
      if (!_disposed && revision == _revision) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> ghiNhanTraLoi({bool? isCorrect}) =>
      _enqueue(() => _engine.ghiNhanTraLoi(isCorrect: isCorrect));

  Future<bool> completeDailyChallenge() async {
    var awarded = false;
    await _enqueue(() async {
      final current = await _repository.load();
      awarded = await _engine.completeDailyChallenge();
      return awarded ? await _repository.load() : current;
    });
    return awarded;
  }

  Future<void> ghiNhanBaiThi(int score, int total, {int? answeredCount}) =>
      _enqueue(
        () => _engine.ghiNhanBaiThi(score, total, answeredCount: answeredCount),
      );

  /// Updates the daily answer target and persists it with the existing model.
  Future<void> updateDailyGoal(int goal) {
    if (![5, 10, 20].contains(goal)) {
      return Future<void>.error(
        ArgumentError.value(goal, 'goal', 'Must be 5, 10, or 20.'),
      );
    }
    return _enqueue(() async {
      final updated = _progress.copyWith(dailyGoal: goal);
      await _repository.save(updated);
      return updated;
    });
  }

  /// Returns and clears badges earned by the latest action for one-time dialogs.
  List<BadgeDefinition> takeNewlyUnlockedBadges() {
    final badges = List<BadgeDefinition>.of(_newBadges);
    _newBadges = const [];
    return badges;
  }

  Future<void> _enqueue(Future<GamificationModel> Function() action) {
    _revision++;
    final completer = Completer<void>();
    _actionQueue = _actionQueue.then((_) async {
      try {
        _progress = await action();
        _newBadges = _engine.huyHieuMoi();
        _errorMessage = null;
      } catch (error) {
        // Gamification storage errors must not interrupt answering or exam flow.
        _errorMessage = error.toString();
      }
      if (!_disposed) notifyListeners();
      completer.complete();
    });
    return completer.future;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
