import 'package:flutter_quiz_bilingual/core/utils/clock.dart';
import 'package:flutter_quiz_bilingual/data/models/gamification_model.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
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

    test(
      'increments on consecutive days and keeps streak within the same day',
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
      },
    );

    test('starts a new streak after a gap longer than one day', () async {
      await engine.ghiNhanTraLoi();
      clock.value = DateTime(2026, 11, 4, 7);

      await engine.ghiNhanTraLoi();

      expect(repository.progress.streak, 1);
      expect(repository.progress.longestStreak, 1);
      expect(repository.progress.lastStudyDate, '2026-11-04');
    });

    test(
      'resets today answer count on a new day before counting today answer',
      () async {
        repository.progress = GamificationModel(
          streak: 4,
          longestStreak: 4,
          lastStudyDate: '2026-11-01',
          todayAnswered: 7,
          totalAnswered: 20,
        );
        clock.value = DateTime(2026, 11, 2, 7);

        await engine.ghiNhanTraLoi();

        expect(repository.progress.todayAnswered, 1);
        expect(repository.progress.totalAnswered, 21);
        expect(repository.progress.lastStudyDate, '2026-11-02');
      },
    );

    test(
      'one missed day is covered once when opening or answering today',
      () async {
        repository.progress = GamificationModel(
          streak: 4,
          longestStreak: 7,
          lastStudyDate: '2026-10-31',
          streakFreezes: 1,
          lastFreezeWeekKey: '2026-W44',
        );
        clock.value = DateTime(2026, 11, 2, 9);

        final refreshed = await engine.refreshForToday();
        expect(refreshed.streak, 4);
        expect(refreshed.streakFreezes, 0);
        expect(refreshed.lastFreezeUsedDateKey, '2026-11-01');
        expect(engine.streakHienThi(refreshed), 4);

        final refreshedAgain = await engine.refreshForToday();
        expect(refreshedAgain.streakFreezes, 0);
        expect(refreshedAgain.streak, 4);

        await engine.ghiNhanTraLoi(isCorrect: true);
        expect(repository.progress.streak, 4);
        expect(repository.progress.streakFreezes, 0);
        expect(repository.progress.lastStudyDate, '2026-11-02');
      },
    );

    test('answer after exactly one missed day spends one freeze', () async {
      repository.progress = GamificationModel(
        streak: 6,
        lastStudyDate: '2026-10-31',
        streakFreezes: 1,
        lastFreezeWeekKey: '2026-W45',
      );
      clock.value = DateTime(2026, 11, 2, 10);

      await engine.ghiNhanTraLoi(isCorrect: true);

      expect(repository.progress.streak, 6);
      expect(repository.progress.streakFreezes, 0);
      expect(repository.progress.lastFreezeUsedDateKey, '2026-11-01');
      expect(repository.progress.lastStudyDate, '2026-11-02');
    });

    test(
      'resets streak after two missed days or when no freeze is available',
      () async {
        repository.progress = GamificationModel(
          streak: 5,
          lastStudyDate: '2026-10-30',
          streakFreezes: 1,
          lastFreezeWeekKey: '2026-W44',
        );
        clock.value = DateTime(2026, 11, 2);
        expect((await engine.refreshForToday()).streak, 0);
        expect(repository.progress.streakFreezes, 1);

        repository.progress = GamificationModel(
          streak: 5,
          lastStudyDate: '2026-10-31',
          streakFreezes: 0,
          lastFreezeWeekKey: '2026-W45',
        );
        expect((await engine.refreshForToday()).streak, 0);
        expect(repository.progress.streakFreezes, 0);
      },
    );

    test('replenishes at most one freeze at the ISO week boundary', () async {
      repository.progress = GamificationModel(
        streakFreezes: 0,
        lastFreezeWeekKey: '2026-W44',
      );
      clock.value = DateTime(2026, 11, 2, 8); // Monday, ISO week 45.

      final refreshed = await engine.refreshForToday();
      expect(refreshed.streakFreezes, 1);
      expect(refreshed.lastFreezeWeekKey, '2026-W45');

      repository.progress = repository.progress.copyWith(streakFreezes: 0);
      expect((await engine.refreshForToday()).streakFreezes, 0);
    });

    test('display streak expires after a missed day', () async {
      await engine.ghiNhanTraLoi();
      clock.value = DateTime(2026, 11, 3);

      expect(engine.streakHienThi(repository.progress), 0);
      // Stored best/current record resets only when a new study action occurs.
      expect(repository.progress.streak, 1);
    });

    test(
      'unlocks answer, streak, first-exam, and perfect-exam badges once',
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
        final newBadgeIds = engine
            .huyHieuMoi()
            .map((badge) => badge.id)
            .toSet();
        expect(newBadgeIds, contains('first_exam'));
        expect(newBadgeIds, contains('perfect_exam'));
        expect(repository.progress.examCount, 1);
        expect(repository.progress.perfectCount, 1);
        expect(
          repository.progress.unlockedBadges['perfect_exam'],
          '2026-11-03',
        );

        await engine.ghiNhanBaiThi(2, 3);
        expect(engine.huyHieuMoi(), isEmpty);
        expect(repository.progress.perfectCount, 1);
      },
    );

    test('calendar day calculation ignores time of day', () async {
      await engine.ghiNhanTraLoi();
      clock.value = DateTime(2026, 11, 2, 0, 1);
      await engine.ghiNhanTraLoi();

      expect(repository.progress.streak, 2);
      expect(
        engine.huyHieuMoi().where(
          (badge) => badge.metric == BadgeMetric.streak,
        ),
        isEmpty,
      );
    });

    test(
      'awards XP for answer outcomes, exam submission, and perfect score',
      () async {
        await engine.ghiNhanTraLoi(isCorrect: true);
        expect(repository.progress.xp, 10);

        await engine.ghiNhanTraLoi(isCorrect: false);
        expect(repository.progress.xp, 12);

        await engine.ghiNhanBaiThi(1, 2, answeredCount: 2);
        expect(repository.progress.xp, 74);

        await engine.ghiNhanBaiThi(2, 2);
        expect(repository.progress.xp, 244);
      },
    );

    test(
      'daily challenge selection is stable per day and changes on another day',
      () {
        final questions = List.generate(
          40,
          (index) => QuestionModel(
            id: 'q$index',
            blockId: 1,
            blockName: const LocalizedText(vi: 'Khá»‘i', en: 'Block'),
            level: 'Nhá»›',
            question: const LocalizedText(vi: 'CÃ¢u?', en: 'Question?'),
            optionsVi: const ['A'],
            optionsEn: const ['A'],
            correctIndex: 0,
            explanation: const LocalizedText(vi: '', en: ''),
          ),
        );
        final first = engine.dailyChallengeQuestions(
          questions,
          forDateKey: '2026-11-01',
        );
        final repeated = engine.dailyChallengeQuestions(
          questions,
          forDateKey: '2026-11-01',
        );
        final nextDay = engine.dailyChallengeQuestions(
          questions,
          forDateKey: '2026-11-02',
        );

        expect(first, hasLength(5));
        expect(
          first.map((question) => question.id).toList(),
          repeated.map((question) => question.id).toList(),
        );
        expect(
          first.map((question) => question.id).toList(),
          isNot(nextDay.map((question) => question.id).toList()),
        );
      },
    );

    test('daily challenge awards 50 XP once per day', () async {
      repository.progress = GamificationModel(xp: 23);
      expect(await engine.completeDailyChallenge(), isTrue);
      expect(repository.progress.xp, 73);
      expect(repository.progress.completedDailyChallengeDateKey, '2026-11-01');

      expect(await engine.completeDailyChallenge(), isFalse);
      expect(repository.progress.xp, 73);

      clock.value = DateTime(2026, 11, 2);
      expect(await engine.completeDailyChallenge(), isTrue);
      expect(repository.progress.xp, 123);
    });

    test('legacy JSON defaults daily challenge completion safely', () {
      final legacy = GamificationModel.fromJson({'xp': 17, 'streak': 2});
      expect(legacy.xp, 17);
      expect(legacy.streak, 2);
      expect(legacy.completedDailyChallengeDateKey, isNull);
      expect(
        GamificationModel.fromJson(legacy.toJson())
            .completedDailyChallengeDateKey,
        isNull,
      );
    });

    test('calculates level thresholds, titles, and next-level progress', () {
      final beforeLevelUp = engine.levelProgressFor(99);
      expect(beforeLevelUp.level, 1);
      expect(beforeLevelUp.titleKey, 'xp_title_newcomer');
      expect(beforeLevelUp.progress, 0.99);
      expect(beforeLevelUp.xpRemaining, 1);

      final dedicated = engine.levelProgressFor(149);
      expect(dedicated.level, 2);
      expect(dedicated.titleKey, 'xp_title_dedicated');
      expect(dedicated.currentLevelXp, 49);
      expect(dedicated.progress, 0.49);

      final master = engine.levelProgressFor(400);
      expect(master.level, 5);
      expect(master.titleKey, 'xp_title_master');
      expect(master.progress, 0);
    });

    test('calculates badge progress from its metric and clamps at target', () {
      final progress = GamificationModel(
        streak: 2,
        totalAnswered: 37,
        examCount: 0,
        perfectCount: 4,
      );

      BadgeDefinition badge(String id) =>
          BadgeCatalog.all.singleWhere((item) => item.id == id);

      expect(badge('answers_50').progressFor(progress), (37, 50));
      expect(badge('streak_3').progressFor(progress), (2, 3));
      expect(badge('first_exam').progressFor(progress), (0, 1));
      expect(badge('perfect_exam').progressFor(progress), (1, 1));
    });
  });
}
