import 'package:flutter_quiz_bilingual/core/utils/clock.dart';
import 'package:flutter_quiz_bilingual/data/models/gamification_model.dart';
import 'package:flutter_quiz_bilingual/domain/gamification/gamification_engine.dart';
import 'package:flutter_quiz_bilingual/domain/gamification/badge_catalog.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/i_gamification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClock implements Clock {
  _FakeClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class _MemoryGamificationRepository implements IGamificationRepository {
  GamificationModel progress = GamificationModel();

  @override
  Future<GamificationModel> load() async => progress;

  @override
  Future<void> save(GamificationModel progress) async {
    this.progress = progress;
  }
}

void main() {
  group('GamificationEngine', () {
    late _FakeClock clock;
    late _MemoryGamificationRepository repository;
    late GamificationEngine engine;

    setUp(() {
      clock = _FakeClock(DateTime(2026, 11, 1, 8));
      repository = _MemoryGamificationRepository();
      engine = GamificationEngine(repository: repository, clock: clock);
    });

    test('increments on consecutive days and keeps streak within the same day',
        () async {
      await engine.ghiNhanTraLoi();
      await engine.ghiNhanTraLoi();

      expect(repository.progress.streak, 1);
      expect(repository.progress.todayAnswered, 2);
      expect(repository.progress.totalAnswered, 2);

      clock.value = DateTime(2026, 11, 2, 22);
      await engine.ghiNhanTraLoi();

      expect(repository.progress.streak, 2);
      expect(repository.progress.longestStreak, 2);
      expect(repository.progress.todayAnswered, 1);
    });

    test('starts a new streak after a gap longer than one day', () async {
      await engine.ghiNhanTraLoi();
      clock.value = DateTime(2026, 11, 4, 7);

      await engine.ghiNhanTraLoi();

      expect(repository.progress.streak, 1);
      expect(repository.progress.longestStreak, 1);
      expect(repository.progress.lastStudyDate, '2026-11-04');
    });

    test('display streak expires after a missed day', () async {
      await engine.ghiNhanTraLoi();
      clock.value = DateTime(2026, 11, 3);

      expect(engine.streakHienThi(repository.progress), 0);
      // Stored best/current record resets only when a new study action occurs.
      expect(repository.progress.streak, 1);
    });

    test('unlocks answer, streak, first-exam, and perfect-exam badges once',
        () async {
      await engine.ghiNhanTraLoi();
      expect(engine.huyHieuMoi().map((badge) => badge.id), ['first_answer']);

      for (var day = 2; day <= 3; day++) {
        clock.value = DateTime(2026, 11, day);
        await engine.ghiNhanTraLoi();
      }
      expect(
        engine.huyHieuMoi().map((badge) => badge.id),
        contains('streak_3'),
      );

      await engine.ghiNhanBaiThi(3, 3);
      final newBadgeIds = engine.huyHieuMoi().map((badge) => badge.id).toSet();
      expect(newBadgeIds, contains('first_exam'));
      expect(newBadgeIds, contains('perfect_exam'));
      expect(repository.progress.examCount, 1);
      expect(repository.progress.perfectCount, 1);
      expect(repository.progress.unlockedBadges['perfect_exam'], '2026-11-03');

      await engine.ghiNhanBaiThi(2, 3);
      expect(engine.huyHieuMoi(), isEmpty);
      expect(repository.progress.perfectCount, 1);
    });

    test('calendar day calculation ignores time of day', () async {
      await engine.ghiNhanTraLoi();
      clock.value = DateTime(2026, 11, 2, 0, 1);
      await engine.ghiNhanTraLoi();

      expect(repository.progress.streak, 2);
      expect(
        engine.huyHieuMoi().where((badge) => badge.metric == BadgeMetric.streak),
        isEmpty,
      );
    });
  });
}
