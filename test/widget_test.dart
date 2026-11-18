import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/quiz_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/language_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/quiz_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/theme_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/screens/home_screen.dart';
import 'package:flutter_quiz_bilingual/presentation/widgets/profile_settings_button.dart';

import 'package:flutter_quiz_bilingual/data/models/quiz_result_model.dart';

class FakeQuizRepository implements IQuizRepository {
  @override
  Future<List<QuestionModel>> loadQuestions() async {
    return [
      const QuestionModel(
        id: 'T01',
        blockId: 1,
        blockName: LocalizedText(vi: 'Dart cơ bản', en: 'Dart Basics'),
        level: 'Nhớ',
        question: LocalizedText(vi: 'Câu hỏi thử nghiệm?', en: 'Test question?'),
        optionsVi: ['A', 'B', 'C', 'D'],
        optionsEn: ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        explanation: LocalizedText(vi: 'Giải thích', en: 'Explanation'),
      ),
    ];
  }

  @override
  Future<List<String>> getWrongQuestionIds() async => [];

  @override
  Future<void> saveWrongQuestion(String id) async {}

  @override
  Future<void> removeWrongQuestion(String id) async {}

  @override
  Future<List<String>> getBookmarkedQuestionIds() async => [];

  @override
  Future<void> saveBookmarkedQuestion(String id) async {}

  @override
  Future<void> removeBookmarkedQuestion(String id) async {}

  @override
  Future<List<QuizResultModel>> getQuizHistory() async => [];

  @override
  Future<void> saveQuizResult(QuizResultModel result) async {}
}

void main() {
  testWidgets('HomeScreen renders title and learning modes', (WidgetTester tester) async {
    final repo = FakeQuizRepository();
    final quizProvider = QuizProvider(repository: repo);
    final langProvider = LanguageProvider();
    final themeProvider = ThemeProvider();

    await quizProvider.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: langProvider),
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: quizProvider),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify main title is displayed
    expect(find.text('Flutter Song Ngữ'), findsOneWidget);

    // Verify Learning Modes exist
    expect(find.text('Chế độ Luyện Tập'), findsOneWidget);
    expect(find.text('Chế độ Thi Thử (Mock Exam)'), findsOneWidget);
    expect(find.text('Làm Lại Câu Sai'), findsOneWidget);
    expect(find.text('Thống Kê Theo Khối Kiến Thức'), findsOneWidget);
  });

  testWidgets('Toggling language via Profile & Settings sheet switches UI between VI and EN', (WidgetTester tester) async {
    final repo = FakeQuizRepository();
    final quizProvider = QuizProvider(repository: repo);
    final langProvider = LanguageProvider();
    final themeProvider = ThemeProvider();

    await quizProvider.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: langProvider),
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: quizProvider),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    // Tap Profile & Settings icon button
    final settingsBtn = find.byType(ProfileSettingsButton);
    expect(settingsBtn, findsOneWidget);
    await tester.tap(settingsBtn);
    await tester.pumpAndSettle();

    // Tap English option in bottom sheet
    final enOption = find.text('English');
    expect(enOption, findsWidgets);
    await tester.tap(enOption.first);
    await tester.pumpAndSettle();

    // Verify UI translated to English
    expect(find.text('Flutter Bilingual Quiz'), findsOneWidget);
    expect(find.text('Practice Mode'), findsOneWidget);
    expect(find.text('Mock Exam (Timed)'), findsOneWidget);
  });
}
