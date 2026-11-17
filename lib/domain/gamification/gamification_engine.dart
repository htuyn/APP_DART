import '../../core/utils/clock.dart';
import '../../core/utils/date_key.dart';
import '../../data/models/gamification_model.dart';
import '../repositories/i_gamification_repository.dart';
import 'badge_catalog.dart';

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

  Future<GamificationModel> ghiNhanTraLoi() async {
    final current = await repository.load();
    final now = clock.now();
    final today = dateKey(now);
    final touched = _touchStudyDay(current, today, answered: 1);
    final updated = _unlockEligible(
      touched.copyWith(totalAnswered: current.totalAnswered + 1),
      today,
    );
    await repository.save(updated);
    return updated;
  }

  Future<GamificationModel> ghiNhanBaiThi(int score, int total) async {
    final current = await repository.load();
    final now = clock.now();
    final today = dateKey(now);
    final touched = _touchStudyDay(current, today);
    final updated = _unlockEligible(
      touched.copyWith(
        examCount: current.examCount + 1,
        perfectCount: current.perfectCount +
            (total > 0 && score == total ? 1 : 0),
      ),
      today,
    );
    await repository.save(updated);
    return updated;
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
    String today, {
    int answered = 0,
  }) {
    final lastDate = current.lastStudyDate;
    if (lastDate == today) {
      return current.copyWith(
        todayAnswered: current.todayAnswered + answered,
      );
    }

    var gap = 2;
    if (lastDate != null) {
      try {
        gap = calendarDaysBetweenKeys(lastDate, today);
      } on FormatException {
        gap = 2;
      }
    }

    // A clock rollback must not move persisted progress backward.
    if (gap < 0) {
      return current.copyWith(
        todayAnswered: current.todayAnswered + answered,
      );
    }

    final nextStreak = gap == 1 ? current.streak + 1 : 1;
    return current.copyWith(
      streak: nextStreak,
      longestStreak:
          nextStreak > current.longestStreak ? nextStreak : current.longestStreak,
      lastStudyDate: today,
      todayAnswered: answered,
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
