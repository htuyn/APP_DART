import '../../data/datasources/ai_tutor_datasource.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/datasources/demo_chat_datasource.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/question_model.dart';
import '../../domain/repositories/ai_repository.dart';

/// Triển khai IAiRepository:
/// - Nếu có `serverUrl` → gọi backend proxy (AI thật qua Gemini).
/// - Nếu không → dùng demo offline từ questions.json.
class AiRepositoryImpl implements IAiRepository {
  final AiTutorDataSource? _tutorDataSource;
  final ChatRemoteDataSource? _remoteDataSource;
  final DemoChatDataSource _demoDataSource;

  AiRepositoryImpl({
    AiTutorDataSource? tutorDataSource,
    ChatRemoteDataSource? remoteDataSource,
    DemoChatDataSource? demoDataSource,
  })  : _tutorDataSource = tutorDataSource,
        _remoteDataSource = remoteDataSource,
        _demoDataSource = demoDataSource ?? DemoChatDataSource();

  @override
  bool get isConnected => _remoteDataSource != null;

  @override
  Future<String> getExplanation({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    String action = 'explain',
  }) {
    if (_tutorDataSource == null) {
      throw Exception('AiTutorDataSource chưa được khởi tạo');
    }
    return _tutorDataSource.requestExplanation(
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
  }) async* {
    if (_remoteDataSource != null) {
      yield* _remoteDataSource.sendMessageStream(
        messages: messages,
        langCode: langCode,
      );
    } else {
      // Demo fallback: lấy tin nhắn người dùng cuối cùng
      final userMsg = messages.lastWhere(
        (m) => m.role == 'user',
        orElse: () => ChatMessageModel(
          role: 'user',
          content: '',
          timestamp: DateTime.now(),
        ),
      ).content;

      final answer = await _demoDataSource.getDemoAnswer(
        userMessage: userMsg,
        langCode: langCode,
      );

      // Phân nhỏ câu trả lời thành từng chunk để mô phỏng streaming
      final words = answer.split(' ');
      for (int i = 0; i < words.length; i++) {
        yield words[i] + (i < words.length - 1 ? ' ' : '');
        await Future.delayed(const Duration(milliseconds: 40));
      }
    }
  }
}
