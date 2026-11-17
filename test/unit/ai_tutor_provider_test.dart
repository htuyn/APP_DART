import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/datasources/ai_tutor_datasource.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/ai_tutor_provider.dart';

void main() {
  group('AiTutorProvider Unit Tests', () {
    late AiTutorProvider aiProvider;

    const sampleQuestion = QuestionModel(
      id: 'K01-001',
      blockId: 1,
      blockName: LocalizedText(vi: 'NgÃ´n ngá»¯ Dart', en: 'Dart Language'),
      level: 'Nhá»›',
      question: LocalizedText(
        vi: 'Tá»« khoÃ¡ nÃ o yÃªu cáº§u háº±ng sá»‘ biÃªn dá»‹ch?',
        en: 'Which keyword requires compile-time constant?',
      ),
      optionsVi: ['final', 'var', 'const', 'late'],
      optionsEn: ['final', 'var', 'const', 'late'],
      correctIndex: 2,
      explanation: LocalizedText(
        vi: 'const táº¡o háº±ng sá»‘ lÃºc biÃªn dá»‹ch.',
        en: 'const creates compile-time constants.',
      ),
    );

    setUp(() {
      aiProvider = AiTutorProvider(
        dataSource: const AiTutorDataSource(isDemoMode: true),
      );
    });

    test('Initial state is idle with empty response', () {
      expect(aiProvider.state, AiTutorState.idle);
      expect(aiProvider.response, '');
      expect(aiProvider.errorMessage, '');
    });

    test('askTutor generates in-depth explanation in demo mode', () async {
      await aiProvider.askTutor(
        question: sampleQuestion,
        userChoiceIndex: 0, // Picked 'final' instead of 'const'
        langCode: 'vi',
        action: 'explain',
      );

      expect(aiProvider.state, AiTutorState.done);
      expect(aiProvider.response.isNotEmpty, true);
      expect(aiProvider.response.contains('const'), true);
      expect(aiProvider.response.contains('NgÃ´n ngá»¯ Dart'), true);
    });

    test('askTutor analyzes why wrong choice was made', () async {
      await aiProvider.askTutor(
        question: sampleQuestion,
        userChoiceIndex: 0,
        langCode: 'vi',
        action: 'why_wrong',
      );

      expect(aiProvider.state, AiTutorState.done);
      expect(aiProvider.response.contains('final'), true);
      expect(aiProvider.response.contains('const'), true);
    });

    test('reset clears tutor state', () async {
      await aiProvider.askTutor(
        question: sampleQuestion,
        userChoiceIndex: 0,
        langCode: 'vi',
      );
      expect(aiProvider.state, AiTutorState.done);

      aiProvider.reset();
      expect(aiProvider.state, AiTutorState.idle);
      expect(aiProvider.response, '');
    });
  });
}
