import 'dart:convert';

import 'package:flutter_quiz_bilingual/data/datasources/gamification_storage_datasource.dart';
import 'package:flutter_quiz_bilingual/data/models/gamification_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns empty progress when no saved value exists', () async {
    final dataSource = GamificationStorageDataSource();

    final progress = await dataSource.load();

    expect(progress.streak, 0);
    expect(progress.totalAnswered, 0);
    expect(progress.unlockedBadges, isEmpty);
  });

  test('loads legacy JSON without dailyGoal or XP using defaults', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      GamificationStorageDataSource.storageKey,
      jsonEncode({
        'streak': 2,
        'longest_streak': 4,
        'last_study_date': '2026-11-16',
        'today_answered': 3,
        'total_answered': 20,
        'exam_count': 1,
        'perfect_count': 0,
        'unlocked_badges': {'first_answer': '2026-11-01'},
      }),
    );

    final progress = await GamificationStorageDataSource().load();

    expect(progress.dailyGoal, 10);
    expect(progress.xp, 0);
    expect(progress.streakFreezes, 1);
    expect(progress.lastFreezeWeekKey, isNull);
    expect(progress.lastFreezeUsedDateKey, isNull);
    expect(progress.todayAnswered, 3);
    expect(progress.unlockedBadges['first_answer'], '2026-11-01');
  });

  test('round-trips the immutable progress model under the versioned key',
      () async {
    final dataSource = GamificationStorageDataSource();
    final progress = GamificationModel(
      streak: 4,
      longestStreak: 8,
      lastStudyDate: '2026-11-17',
      todayAnswered: 6,
      dailyGoal: 20,
      xp: 250,
      streakFreezes: 0,
      lastFreezeWeekKey: '2026-W46',
      lastFreezeUsedDateKey: '2026-11-16',
      totalAnswered: 42,
      examCount: 3,
      perfectCount: 1,
      unlockedBadges: const {
        'first_answer': '2026-11-01',
        'perfect_exam': '2026-11-17',
      },
    );

    await dataSource.save(progress);
    final restored = await dataSource.load();

    expect(restored.streak, 4);
    expect(restored.longestStreak, 8);
    expect(restored.lastStudyDate, '2026-11-17');
    expect(restored.todayAnswered, 6);
    expect(restored.dailyGoal, 20);
    expect(restored.xp, 250);
    expect(restored.streakFreezes, 0);
    expect(restored.lastFreezeWeekKey, '2026-W46');
    expect(restored.lastFreezeUsedDateKey, '2026-11-16');
    expect(restored.totalAnswered, 42);
    expect(restored.examCount, 3);
    expect(restored.perfectCount, 1);
    expect(restored.unlockedBadges, progress.unlockedBadges);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(GamificationStorageDataSource.storageKey), isNotNull);
  });
}
