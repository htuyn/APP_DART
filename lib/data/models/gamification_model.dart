/// Immutable persisted progress for streaks, answers, exams, and badges.
class GamificationModel {
  GamificationModel({
    this.streak = 0,
    this.longestStreak = 0,
    this.lastStudyDate,
    this.todayAnswered = 0,
    this.dailyGoal = 10,
    this.xp = 0,
    this.totalAnswered = 0,
    this.examCount = 0,
    this.perfectCount = 0,
    Map<String, String> unlockedBadges = const {},
  }) : unlockedBadges = Map.unmodifiable(unlockedBadges);

  final int streak;
  final int longestStreak;

  /// Calendar key in yyyy-MM-dd format.
  final String? lastStudyDate;

  final int todayAnswered;
  final int dailyGoal;
  final int xp;
  final int totalAnswered;
  final int examCount;
  final int perfectCount;

  /// Maps badge ID to the yyyy-MM-dd date on which it was unlocked.
  final Map<String, String> unlockedBadges;

  GamificationModel copyWith({
    int? streak,
    int? longestStreak,
    String? lastStudyDate,
    bool clearLastStudyDate = false,
    int? todayAnswered,
    int? dailyGoal,
    int? xp,
    int? totalAnswered,
    int? examCount,
    int? perfectCount,
    Map<String, String>? unlockedBadges,
  }) {
    return GamificationModel(
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudyDate:
          clearLastStudyDate ? null : lastStudyDate ?? this.lastStudyDate,
      todayAnswered: todayAnswered ?? this.todayAnswered,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      xp: xp ?? this.xp,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      examCount: examCount ?? this.examCount,
      perfectCount: perfectCount ?? this.perfectCount,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
    );
  }

  Map<String, dynamic> toJson() => {
        'streak': streak,
        'longest_streak': longestStreak,
        'last_study_date': lastStudyDate,
        'today_answered': todayAnswered,
        'daily_goal': dailyGoal,
        'xp': xp,
        'total_answered': totalAnswered,
        'exam_count': examCount,
        'perfect_count': perfectCount,
        'unlocked_badges': unlockedBadges,
      };

  factory GamificationModel.fromJson(Map<String, dynamic> json) {
    final rawBadges = json['unlocked_badges'];
    final badges = <String, String>{};
    if (rawBadges is Map) {
      for (final entry in rawBadges.entries) {
        if (entry.key is String && entry.value is String) {
          badges[entry.key as String] = entry.value as String;
        }
      }
    }

    int readInt(String key) {
      final value = json[key];
      return value is num ? value.toInt() : 0;
    }

    return GamificationModel(
      streak: readInt('streak'),
      longestStreak: readInt('longest_streak'),
      lastStudyDate: json['last_study_date'] as String?,
      todayAnswered: readInt('today_answered'),
      dailyGoal: json['daily_goal'] is num
          ? (json['daily_goal'] as num).toInt()
          : 10,
      xp: readInt('xp'),
      totalAnswered: readInt('total_answered'),
      examCount: readInt('exam_count'),
      perfectCount: readInt('perfect_count'),
      unlockedBadges: badges,
    );
  }
}
