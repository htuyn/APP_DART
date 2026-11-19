import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_quiz_bilingual/data/datasources/demo_chat_datasource.dart';
import 'package:flutter_quiz_bilingual/data/models/chat_message_model.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/ai_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/chat_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/language_provider.dart';
import 'package:flutter_quiz_bilingual/presentation/screens/ai_chat_screen.dart';

class _FakeAiRepository implements IAiRepository {
  @override
  bool get isConnected => true;

  @override
  Future<String> getExplanation({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    String action = 'explain',
  }) async =>
      '';

  @override
  Stream<String> sendMessageStream({
    required List<ChatMessageModel> messages,
    required String langCode,
    QuestionModel? activeQuestion,
    int? userChoiceIndex,
  }) async* {
    yield '**FutureBuilder** giúp dựng UI theo trạng thái của Future.';
  }
}

class _FakeDemoDataSource extends DemoChatDataSource {
  const _FakeDemoDataSource();
}

void main() {
  testWidgets('AiChatScreen shows welcome panel and renders an AI answer',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final lang = LanguageProvider();
    final chat = ChatProvider(
      customRepository: _FakeAiRepository(),
      demoDataSource: const _FakeDemoDataSource(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: lang),
          ChangeNotifierProvider.value(value: chat),
        ],
        child: const MaterialApp(home: AiChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('AI Tutor'), findsWidgets);

    final suggestionFinder = find.textContaining('FutureBuilder');
    await tester.ensureVisible(suggestionFinder);
    await tester.pumpAndSettle();
    await tester.tap(suggestionFinder);
    await tester.pumpAndSettle();

    expect(chat.state, ChatState.done);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('FutureBuilder'), findsWidgets);

    lang.dispose();
    chat.dispose();
  });
}
