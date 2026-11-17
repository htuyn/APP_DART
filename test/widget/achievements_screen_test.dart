import 'package:material_ui/material_ui.dart';
import 'package:flutter_quiz_bilingual/core/utils/clock.dart';
import 'package:flutter_quiz_bilingual/data/models/gamification_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/i_gamification_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/gamification_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/language_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/screens/achievements_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 11, 17, 12);
}

class _FakeGamificationRepository implements IGamificationRepository {
  _FakeGamificationRepository(this.progress);

  GamificationModel progress;

  @override
  Future<GamificationModel> load() async => progress;

  @override
  Future<void> save(GamificationModel progress) async {
    this.progress = progress;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows streak, badge states, and accessible badge tiles',
      (tester) async {
    final languageProvider = LanguageProvider();
    final repository = _FakeGamificationRepository(
      GamificationModel(
          streak: 3,
          longestStreak: 5,
          lastStudyDate: '2026-11-17',
          todayAnswered: 3,
          dailyGoal: 10,
          xp: 135,
          totalAnswered: 12,
          unlockedBadges: const {'first_answer': '2026-11-01'},
      ),
    );
    final gamificationProvider = GamificationProvider(
      repository: repository,
      clock: _FixedClock(),
    );
    await gamificationProvider.initialize();

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: languageProvider),
          ChangeNotifierProvider.value(value: gamificationProvider),
        ],
        child: const MaterialApp(home: AchievementsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thành tích'), findsOneWidget);
    expect(find.text('3 ngày liên tiếp'), findsOneWidget);
    expect(find.text('3/10 câu hôm nay'), findsOneWidget);
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text('Cấp 2 · Người chăm học'), findsOneWidget);
    expect(find.text('135 XP'), findsOneWidget);
    expect(find.text('35/100 XP'), findsOneWidget);
    expect(
      tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('xp-level-progress')),
      ).value,
      0.35,
    );
    expect(
      tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      ).value,
      0.3,
    );
    for (final goal in const [5, 10, 20]) {
      expect(
        tester.getSize(find.byKey(ValueKey('daily-goal-$goal'))).height,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.tap(find.byKey(const ValueKey('daily-goal-20')));
    await tester.pumpAndSettle();
    expect(gamificationProvider.progress.dailyGoal, 20);
    expect(repository.progress.dailyGoal, 20);

    await tester.scrollUntilVisible(
      find.text('12/50'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Bước đầu tiên'), findsOneWidget);
    expect(find.text('Đã mở khóa · 2026-11-01'), findsOneWidget);
    expect(find.text('Điểm tuyệt đối'), findsOneWidget);
    expect(find.text('12/50'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(8));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
    gamificationProvider.dispose();
    languageProvider.dispose();
  });
}
