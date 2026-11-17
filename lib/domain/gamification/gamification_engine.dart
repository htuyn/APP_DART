import '../../core/utils/clock.dart';
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

  Future<GamificationModel> ghiNhanTraLoi({bool? isCorrect}) async {
    final current = await repository.load();
    final now = clock.now();
    final today = dateKey(now);
    final touched = _touchStudyDay(current, today);
    final updated = _unlockEligible(
      touched.copyWith(
        todayAnswered: touched.todayAnswered + 1,
        totalAnswered: current.totalAnswered + 1,
        xp: current.xp +
            (isCorrect == null ? 0 : isCorrect ? 10 : 2),
      ),
      today,
    );
    await repository.save(updated);
    return updated;
  }

  Future<GamificationModel> ghiNhanBaiThi(
    int score,
    int total, {
    int? answeredCount,
  }) async {
    final current = await repository.load();
    final now = clock.now();
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
      final gap = calendarDaysBetweenKeys(lastStudyDate, dateKey(clock.now()));
      return gap <= 1 ? progress.streak : 0;
    } on FormatException {
      return 0;
    }
  }

  /// Badges unlocked by the most recent recorded action.
  List<BadgeDefinition> huyHieuMoi() => List.unmodifiable(_newBadges);

  GamificationModel _touchStudyDay(
    GamificationModel current,
    String today,
  ) {
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

    final nextStreak = gap == 1 ? current.streak + 1 : 1;
    return current.copyWith(
      streak: nextStreak,
      longestStreak:
          nextStreak > current.longestStreak ? nextStreak : current.longestStreak,
      lastStudyDate: today,
      todayAnswered: 0,
    );
  }

  GamificationModel _unlockEligible(
    GamificationModel progress,
    String today,
  ) {
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
