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

  test('round-trips the immutable progress model under the versioned key',
      () async {
    final dataSource = GamificationStorageDataSource();
    final progress = GamificationModel(
      streak: 4,
      longestStreak: 8,
      lastStudyDate: '2026-11-17',
      todayAnswered: 6,
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
    expect(restored.totalAnswered, 42);
    expect(restored.examCount, 3);
    expect(restored.perfectCount, 1);
    expect(restored.unlockedBadges, progress.unlockedBadges);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(GamificationStorageDataSource.storageKey), isNotNull);
  });
}
