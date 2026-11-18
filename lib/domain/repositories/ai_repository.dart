import '../../data/models/chat_message_model.dart';
import '../../data/models/question_model.dart';

abstract class IAiRepository {
  /// Lấy giải thích cho một câu hỏi trắc nghiệm (giữ nguyên tính năng cũ).
  Future<String> getExplanation({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    String action = 'explain',
  });

  /// Gửi tin nhắn chat tự do và nhận stream phản hồi từ AI.
  Stream<String> sendMessageStream({
    required List<ChatMessageModel> messages,
    required String langCode,
  });

  /// Kiểm tra xem có kết nối AI thật (proxy) hay chỉ chạy demo offline.
  bool get isConnected;
}
