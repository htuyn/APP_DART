import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/datasources/demo_chat_datasource.dart';
import 'package:flutter_quiz_bilingual/data/models/chat_message_model.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/ai_repository.dart';
import 'package:flutter_quiz_bilingual/presentation/providers/chat_provider.dart';

class _FakeAiRepository implements IAiRepository {
  bool fail = false;
  List<String> chunks = const ['Xin ', 'chào'];
  final List<List<ChatMessageModel>> calls = [];
  final List<QuestionModel?> activeQuestions = [];

  // isConnected = true → chat provider sử dụng fake repo thật sự
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
    calls.add(messages);
    activeQuestions.add(activeQuestion);
    if (fail) throw Exception('proxy lỗi');
    for (final chunk in chunks) {
      yield chunk;
    }
  }
}

class _FakeDemoDataSource extends DemoChatDataSource {
  const _FakeDemoDataSource();

  @override
  Future<String> getDemoAnswer({
    required String userMessage,
    required String langCode,
    QuestionModel? activeQuestion,
    int? userChoiceIndex,
  }) async =>
      'Trả lời offline';
}

const _questionA = QuestionModel(
  id: 'Q-A',
  blockId: 1,
  blockName: LocalizedText(vi: 'Dart', en: 'Dart'),
  level: 'Nhớ',
  question: LocalizedText(vi: 'Câu A?', en: 'Question A?'),
  optionsVi: ['a', 'b', 'c', 'd'],
  optionsEn: ['a', 'b', 'c', 'd'],
  correctIndex: 2,
  explanation: LocalizedText(vi: 'Giải thích A', en: 'Explanation A'),
);

const _questionB = QuestionModel(
  id: 'Q-B',
  blockId: 1,
  blockName: LocalizedText(vi: 'Flutter', en: 'Flutter'),
  level: 'Nhớ',
  question: LocalizedText(vi: 'Câu B?', en: 'Question B?'),
  optionsVi: ['a', 'b', 'c', 'd'],
  optionsEn: ['a', 'b', 'c', 'd'],
  correctIndex: 0,
  explanation: LocalizedText(vi: 'Giải thích B', en: 'Explanation B'),
);

void main() {
  group('ChatProvider', () {
    late _FakeAiRepository repository;
    late ChatProvider provider;

    setUp(() {
      repository = _FakeAiRepository();
      provider = ChatProvider(
        customRepository: repository,
        demoDataSource: const _FakeDemoDataSource(),
      );
    });

    tearDown(() => provider.dispose());

    test('sendMessage streams answer and only sends non-empty history', () async {
      await provider.sendMessage(content: 'Xin chào', langCode: 'vi');

      expect(provider.state, ChatState.done);
      expect(provider.messages.last.role, 'assistant');
      expect(provider.messages.last.content, 'Xin chào');

      final sent = repository.calls.single;
      expect(sent.length, 1);
      expect(sent.single.role, 'user');
      expect(sent.single.content, 'Xin chào');
    });

    test('openWithQuestionContext sets greeting and context without auto-sending prompt', () async {
      provider.openWithQuestionContext(question: _questionA, langCode: 'vi');
      await pumpEventQueue();

      expect(repository.calls.length, 0); // Không tự động gọi API
      expect(provider.messages.where((m) => m.role == 'user').isEmpty, true); // Không tự tạo user message
      expect(provider.messages.where((m) => m.role == 'assistant').isNotEmpty, true); // Có lời chào AI
      expect(provider.hasActiveQuestion, true);
      expect(provider.activeQuestion?.id, 'Q-A');

      // Khi chuyển sang question B
      provider.openWithQuestionContext(question: _questionB, langCode: 'vi');
      await pumpEventQueue();

      expect(repository.calls.length, 0); // Vẫn không tự động gọi API
      expect(provider.activeQuestion?.id, 'Q-B');

      // Khi người dùng gửi câu hỏi, context câu B được truyền vào repository
      await provider.sendMessage(content: 'Tại sao?', langCode: 'vi');
      expect(repository.calls.length, 1);
      expect(repository.activeQuestions.single?.id, 'Q-B');
    });

    test('shows error when connected provider fails', () async {
      repository.fail = true;

      await provider.sendMessage(content: 'Xin chào', langCode: 'vi');

      // isConnected = true → lỗi API phải hiển thị lỗi, không silent fallback
      expect(provider.state, ChatState.error);
      expect(provider.errorMessage, isNotEmpty);
      expect(provider.usedFallback, false);
    });

    test('retryLastMessage re-sends the latest question', () async {
      repository.fail = true;
      await provider.sendMessage(content: 'Xin chào', langCode: 'vi');
      expect(provider.state, ChatState.error); // isConnected=true → error not fallback

      repository
        ..fail = false
        ..chunks = const ['Đã ', 'trả lời'];

      await provider.retryLastMessage();

      expect(repository.calls.length, greaterThanOrEqualTo(1));
      expect(provider.usedFallback, false);
      expect(provider.state, ChatState.done);
      expect(provider.messages.last.content, 'Đã trả lời');
    });

    test('clearChat and startNewChat reset conversation cleanly', () async {
      await provider.sendMessage(content: 'Xin chào', langCode: 'vi');
      provider.clearChat();

      expect(provider.hasConversation, false);
      expect(provider.messages.length, 1);
      expect(provider.messages.single.role, 'system');
      expect(provider.state, ChatState.idle);

      await provider.sendMessage(content: 'Câu hỏi mới', langCode: 'vi');
      provider.startNewChat();
      expect(provider.hasConversation, false);
      expect(provider.state, ChatState.idle);
    });

    test('stopStreaming halts streaming and sets done', () async {
      provider.sendMessage(content: 'Xin chào', langCode: 'vi');
      provider.stopStreaming();
      expect(provider.state, ChatState.done);
      expect(provider.isStreaming, false);
    });
  });
}
