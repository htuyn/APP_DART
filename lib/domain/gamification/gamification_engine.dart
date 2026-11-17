import 'dart:math';

import '../../core/utils/clock.dart';
import '../../data/models/question_model.dart';
import '../../core/utils/date_key.dart';
import '../../data/models/gamification_model.dart';
import '../repositories/i_gamification_repository.dart';
import 'badge_catalog.dart';

/// XP and level summary used by the presentation layer.
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.titleKey,
    required this.currentLevelXp,
    required this.xpForNextLevel,
    required this.progress,
  });

  final int level;
  final String titleKey;
  final int currentLevelXp;
  final int xpForNextLevel;
  final double progress;

  int get xpRemaining => xpForNextLevel - currentLevelXp;
}

/// Domain service for date-based study streaks and badge unlocks.
class GamificationEngine {
  GamificationEngine({
    required this.repository,
    this.clock = const SystemClock(),
  });

  final IGamificationRepository repository;
  final Clock clock;
  List<BadgeDefinition> _newBadges = const [];

  Future<GamificationModel> load() => repository.load();

  String get todayDateKey => dateKey(clock.now());

  /// Reconciles weekly freeze replenishment and missed days when the app opens.
  Future<GamificationModel> refreshForToday() async {
    final now = clock.now();
    final today = dateKey(now);
    final current = _refreshFreezeWeek(await repository.load(), now);
    final updated = _refreshMissedDays(current, today);
    await repository.save(updated);
    return updated;
  }

  Future<GamificationModel> ghiNhanTraLoi({bool? isCorrect}) async {
    final now = clock.now();
    final current = _refreshFreezeWeek(await repository.load(), now);
    final today = dateKey(now);
    final touched = _touchStudyDay(current, today);
    final updated = _unlockEligible(
      touched.copyWith(
        todayAnswered: touched.todayAnswered + 1,
        totalAnswered: current.totalAnswered + 1,
        xp:
            current.xp +
            (isCorrect == null
                ? 0
                : isCorrect
                ? 10
                : 2),
      ),
      today,
    );
    await repository.save(updated);
    return updated;
  }

  /// Selects a stable daily set from the full question bank.
  List<QuestionModel> dailyChallengeQuestions(
    List<QuestionModel> questions, {
    String? forDateKey,
  }) {
    final key = forDateKey ?? dateKey(clock.now());
    final seed = key.codeUnits.fold<int>(0, (value, unit) => value * 31 + unit);
    final shuffled = List<QuestionModel>.of(questions)..shuffle(Random(seed));
    return List.unmodifiable(shuffled.take(min(5, shuffled.length)));
  }

  /// Awards the daily challenge bonus once per calendar day.
  Future<bool> completeDailyChallenge() async {
    final today = dateKey(clock.now());
    final current = await repository.load();
    if (current.completedDailyChallengeDateKey == today) return false;
    await repository.save(
      current.copyWith(
        xp: current.xp + 50,
        completedDailyChallengeDateKey: today,
      ),
    );
    return true;
  }

  Future<GamificationModel> ghiNhanBaiThi(
    int score,
    int total, {
    int? answeredCount,
  }) async {
    final now = clock.now();
    final current = _refreshFreezeWeek(await repository.load(), now);
    final today = dateKey(now);
    final touched = _touchStudyDay(current, today);
    final answered = (answeredCount ?? total).clamp(0, total);
    final correct = score.clamp(0, answered);
    final perfect = total > 0 && score == total;
    final answerXp = correct * 10 + (answered - correct) * 2;
    final updated = _unlockEligible(
      touched.copyWith(
        examCount: current.examCount + 1,
        perfectCount: current.perfectCount + (perfect ? 1 : 0),
        xp: current.xp + 50 + answerXp + (perfect ? 100 : 0),
      ),
      today,
    );
    await repository.save(updated);
    return updated;
  }

  /// Levels require 100 XP each. Titles advance at levels 1, 2, and 5.
  LevelProgress levelProgressFor(int xp) {
    final safeXp = xp < 0 ? 0 : xp;
    final level = safeXp ~/ 100 + 1;
    final currentLevelXp = safeXp % 100;
    final titleKey = switch (level) {
      1 => 'xp_title_newcomer',
      >= 2 && < 5 => 'xp_title_dedicated',
      _ => 'xp_title_master',
    };
    return LevelProgress(
      level: level,
      titleKey: titleKey,
      currentLevelXp: currentLevelXp,
      xpForNextLevel: 100,
      progress: currentLevelXp / 100,
    );
  }

  /// Returns zero when the last study date is more than one calendar day ago.
  int streakHienThi(GamificationModel progress) {
    final lastStudyDate = progress.lastStudyDate;
    if (lastStudyDate == null || progress.streak <= 0) return 0;
    try {
      final today = dateKey(clock.now());
      final gap = calendarDaysBetweenKeys(lastStudyDate, today);
      if (gap <= 1) return progress.streak;
      if (gap == 2 && _freezeCoversGap(lastStudyDate, today, progress)) {
        return progress.streak;
      }
      return 0;
    } on FormatException {
      return 0;
    }
  }

  /// Badges unlocked by the most recent recorded action.
  List<BadgeDefinition> huyHieuMoi() => List.unmodifiable(_newBadges);

  GamificationModel _touchStudyDay(GamificationModel current, String today) {
    final lastDate = current.lastStudyDate;
    if (lastDate == today) return current;

    var gap = 2;
    if (lastDate != null) {
      try {
        gap = calendarDaysBetweenKeys(lastDate, today);
      } on FormatException {
        gap = 2;
      }
    }

    // A clock rollback must not move persisted progress backward.
    if (gap < 0) return current;

    if (lastDate != null && gap == 2) {
      final missingDate = _nextDateKey(lastDate);
      final alreadyProtected = current.lastFreezeUsedDateKey == missingDate;
      if (alreadyProtected) {
        return current.copyWith(lastStudyDate: today, todayAnswered: 0);
      }
      if (current.streak > 0 && current.streakFreezes > 0) {
        return current.copyWith(
          lastStudyDate: today,
          todayAnswered: 0,
          streakFreezes: current.streakFreezes - 1,
          lastFreezeUsedDateKey: missingDate,
        );
      }
    }

    final nextStreak = gap == 1 ? current.streak + 1 : 1;
    return current.copyWith(
      streak: nextStreak,
      longestStreak: nextStreak > current.longestStreak
          ? nextStreak
          : current.longestStreak,
      lastStudyDate: today,
      todayAnswered: 0,
    );
  }

  GamificationModel _refreshFreezeWeek(
    GamificationModel progress,
    DateTime now,
  ) {
    final currentWeek = _isoWeekKey(now);
    final previousWeek = progress.lastFreezeWeekKey;
    final cappedFreezes = progress.streakFreezes.clamp(0, 1);
    if (previousWeek == null || previousWeek.isEmpty) {
      return progress.copyWith(
        streakFreezes: cappedFreezes,
        lastFreezeWeekKey: currentWeek,
      );
    }
    if (currentWeek.compareTo(previousWeek) > 0) {
      return progress.copyWith(
        streakFreezes: 1,
        lastFreezeWeekKey: currentWeek,
      );
    }
    return cappedFreezes == progress.streakFreezes
        ? progress
        : progress.copyWith(streakFreezes: cappedFreezes);
  }

  GamificationModel _refreshMissedDays(
    GamificationModel progress,
    String today,
  ) {
    final lastDate = progress.lastStudyDate;
    if (lastDate == null || progress.streak <= 0) return progress;

    int gap;
    try {
      gap = calendarDaysBetweenKeys(lastDate, today);
    } on FormatException {
      return progress.copyWith(streak: 0);
    }

    if (gap < 0 || gap <= 1) return progress;
    if (gap == 2) {
      final missingDate = _nextDateKey(lastDate);
      if (progress.lastFreezeUsedDateKey == missingDate) return progress;
      if (progress.streakFreezes > 0) {
        return progress.copyWith(
          streakFreezes: progress.streakFreezes - 1,
          lastFreezeUsedDateKey: missingDate,
        );
      }
    }
    return progress.copyWith(streak: 0);
  }

  bool _freezeCoversGap(
    String lastDate,
    String today,
    GamificationModel progress,
  ) {
    try {
      final usedDate = progress.lastFreezeUsedDateKey;
      return usedDate != null &&
          calendarDaysBetweenKeys(lastDate, usedDate) == 1 &&
          calendarDaysBetweenKeys(usedDate, today) == 1;
    } on FormatException {
      return false;
    }
  }

  String _nextDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) throw const FormatException('Invalid date key');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    return dateKey(date.add(const Duration(days: 1)));
  }

  String _isoWeekKey(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final thursday = day.add(Duration(days: 4 - day.weekday));
    final weekYear = thursday.year;
    final januaryFourth = DateTime(weekYear, 1, 4);
    final firstThursday = januaryFourth.add(
      Duration(days: 4 - januaryFourth.weekday),
    );
    final week = thursday.difference(firstThursday).inDays ~/ 7 + 1;
    return '$weekYear-W${week.toString().padLeft(2, '0')}';
  }

  GamificationModel _unlockEligible(GamificationModel progress, String today) {
    _newBadges = const [];
    final earned = <BadgeDefinition>[];
    final unlocked = Map<String, String>.of(progress.unlockedBadges);

    for (final badge in BadgeCatalog.all) {
      if (!unlocked.containsKey(badge.id) && badge.isEarned(progress)) {
        unlocked[badge.id] = today;
        earned.add(badge);
      }
    }

    _newBadges = List.unmodifiable(earned);
    return progress.copyWith(unlockedBadges: unlocked);
  }
}
