import '../../data/datasources/ai_tutor_datasource.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/demo_chat_datasource.dart';
import '../../data/datasources/gemini_direct_datasource.dart';
import '../../data/datasources/openrouter_datasource.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/question_model.dart';
import '../../domain/repositories/ai_repository.dart';

/// Triển khai IAiRepository:
/// 1. OpenRouter → OpenRouterDataSource (nếu được chọn và có key).
/// 2. Gemini → GeminiDirectDataSource (nếu được chọn và có key).
/// 3. Remote Proxy → ChatRemoteDataSource (dự phòng).
/// 4. Offline → DemoChatDataSource.
class AiRepositoryImpl implements IAiRepository {
  final AiTutorDataSource? tutorDataSource;
  final GeminiDirectDataSource? directDataSource;
  final ChatRemoteDataSource? remoteDataSource;
  final OpenRouterDataSource? openRouterDataSource;
  final DemoChatDataSource demoDataSource;

  AiRepositoryImpl({
    this.tutorDataSource,
    this.directDataSource,
    this.remoteDataSource,
    this.openRouterDataSource,
    DemoChatDataSource? demoDataSource,
  }) : demoDataSource = demoDataSource ?? const DemoChatDataSource();

  @override
  bool get isConnected =>
      (openRouterDataSource != null && openRouterDataSource!.hasKey) ||
      (directDataSource != null && directDataSource!.hasKey) ||
      remoteDataSource != null;

  @override
  Future<String> getExplanation({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    String action = 'explain',
  }) {
    if (tutorDataSource == null) {
      throw Exception('AiTutorDataSource chưa được khởi tạo');
    }
    return tutorDataSource!.requestExplanation(
      question: question,
      userChoiceIndex: userChoiceIndex,
      langCode: langCode,
      action: action,
    );
  }

  @override
  Stream<String> sendMessageStream({
    required List<ChatMessageModel> messages,
    required String langCode,
    QuestionModel? activeQuestion,
    int? userChoiceIndex,
  }) async* {
    // 1. Ưu tiên OpenRouter nếu được cấu hình
    if (openRouterDataSource != null && openRouterDataSource!.hasKey) {
      yield* openRouterDataSource!.sendMessageStream(
        messages: messages,
        langCode: langCode,
      );
      return;
    }

    // 2. Gemini Direct nếu có API Key
    if (directDataSource != null && directDataSource!.hasKey) {
      yield* directDataSource!.sendMessageStream(
        messages: messages,
        langCode: langCode,
      );
      return;
    }

    // 3. Remote Proxy nếu có cấu hình
    if (remoteDataSource != null) {
      yield* remoteDataSource!.sendMessageStream(
        messages: messages,
        langCode: langCode,
      );
      return;
    }

    // 4. Offline fallback
    final userMsg = messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => ChatMessageModel(
        role: 'user',
        content: '',
        timestamp: DateTime.now(),
      ),
    ).content;

    final answer = await demoDataSource.getDemoAnswer(
      userMessage: userMsg,
      langCode: langCode,
      activeQuestion: activeQuestion,
      userChoiceIndex: userChoiceIndex,
    );

    final words = answer.split(' ');
    for (int i = 0; i < words.length; i++) {
      yield words[i] + (i < words.length - 1 ? ' ' : '');
      await Future.delayed(const Duration(milliseconds: 25));
    }
  }
}
