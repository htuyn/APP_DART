import 'package:material_ui/material_ui.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/data/models/quiz_result_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/quiz_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/language_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/quiz_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/screens/cau_hoi_da_luu_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeQuizRepo implements IQuizRepository {
  final List<QuestionModel> questions;
  final List<String> bookmarkedIds;

  _FakeQuizRepo(this.questions, this.bookmarkedIds);

  @override
  Future<List<QuestionModel>> loadQuestions() async => questions;
  @override
  Future<List<String>> getWrongQuestionIds() async => [];
  @override
  Future<void> saveWrongQuestion(String questionId) async {}
  @override
  Future<void> removeWrongQuestion(String questionId) async {}
  @override
  Future<List<String>> getBookmarkedQuestionIds() async => bookmarkedIds;
  @override
  Future<void> saveBookmarkedQuestion(String questionId) async {
    if (!bookmarkedIds.contains(questionId)) bookmarkedIds.add(questionId);
  }
  @override
  Future<void> removeBookmarkedQuestion(String questionId) async {
    bookmarkedIds.remove(questionId);
  }
  @override
  Future<List<QuizResultModel>> getQuizHistory() async => [];
  @override
  Future<void> saveQuizResult(QuizResultModel result) async {}
}

void main() {
  testWidgets('CauHoiDaLuuScreen hiển thị giao diện rỗng khi chưa có câu hỏi nào được lưu', (tester) async {
    final repo = _FakeQuizRepo([], []);
    final quizProvider = QuizProvider(repository: repo);
    await quizProvider.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider.value(value: quizProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const CauHoiDaLuuScreen(),
        ),
      ),
    );

    expect(find.text('Chưa có câu hỏi nào được lưu'), findsOneWidget);
  });

  testWidgets('CauHoiDaLuuScreen renders bookmarked questions', (tester) async {
    final question = const QuestionModel(
      id: 'Q_BOOK',
      blockId: 1,
      blockName: LocalizedText(vi: 'Cơ bản', en: 'Basics'),
      level: 'Dễ',
      question: LocalizedText(vi: 'Câu hỏi đã ghim?', en: 'Bookmarked question?'),
      optionsVi: ['Đáp án A', 'Đáp án B'],
      optionsEn: ['Option A', 'Option B'],
      correctIndex: 0,
      explanation: LocalizedText(vi: 'Giải thích A', en: 'Explanation A'),
    );

    final repo = _FakeQuizRepo([question], ['Q_BOOK']);
    final quizProvider = QuizProvider(repository: repo);
    await quizProvider.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider.value(value: quizProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const CauHoiDaLuuScreen(),
        ),
      ),
    );

    expect(find.text('Câu hỏi đã ghim?'), findsOneWidget);
    expect(find.text('Đáp án A'), findsOneWidget);
  });
}
