import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/chat_message_model.dart';
import '../models/question_model.dart';

/// Datasource gọi trực tiếp OpenRouter API (openrouter.ai/api/v1/chat/completions).
/// Tương thích OpenAI Chat Completions format.
/// Hỗ trợ streaming Server-Sent Events.
class OpenRouterDataSource {
  final String apiKey;
  final String model;

  static const _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  const OpenRouterDataSource({
    required this.apiKey,
    required this.model,
  });

  bool get hasKey => apiKey.trim().isNotEmpty;

  /// Định dạng khối ngữ cảnh câu hỏi bài học hiện tại
  String _buildContextText({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
  }) {
    final isVi = langCode == 'vi';
    final block = question.blockName.getText(langCode);
    final qText = question.question.getText(langCode);
    final options = question.getOptions(langCode);
    final correct = options[question.correctIndex];
    final explanation = question.explanation.getText(langCode);
    final userChoice = (userChoiceIndex != null && userChoiceIndex < options.length)
        ? options[userChoiceIndex]
        : null;

    final optionsList = options
        .asMap()
        .entries
        .map((e) => '   ${String.fromCharCode(65 + e.key)}. ${e.value}')
        .join('\n');

    return isVi
        ? '''[NGỮ CẢNH CÂU HỎI BÀI HỌC HIỆN TẠI]:
- Khối kiến thức: $block
- Nội dung câu hỏi: $qText
- Các đáp án lựa chọn:
$optionsList
- Đáp án chính xác: $correct
${userChoice != null ? '- Lựa chọn của người dùng: $userChoice\n' : ''}${explanation.isNotEmpty ? '- Giải thích bài học: $explanation\n' : ''}
LƯU Ý QUAN TRỌNG: Người dùng đang trao đổi về câu hỏi này. Khi người dùng đặt câu hỏi ("Tại sao?", "Vì sao đáp án này đúng?", "Tại sao đúng?", "Giải thích", "Cho ví dụ"), BẮT BUỘC phải trả lời dựa trên câu hỏi và đáp án ở trên, tuyệt đối không hỏi lại người dùng về nội dung câu hỏi.'''
        : '''[CURRENT QUIZ QUESTION CONTEXT]:
- Topic: $block
- Question: $qText
- Options:
$optionsList
- Correct Answer: $correct
${userChoice != null ? '- User Selected: $userChoice\n' : ''}${explanation.isNotEmpty ? '- Explanation: $explanation\n' : ''}
IMPORTANT NOTE: The user is discussing this question. When they ask follow-up questions ("Why?", "Why is this answer correct?", "Explain", "Give an example"), you MUST answer based on the question and correct answer above. Never ask the user to repeat or provide the question again.''';
  }

  /// System prompt song ngữ cho AI Tutor kèm ngữ cảnh câu hỏi nếu có
  String _buildSystemPrompt(
    String langCode, {
    QuestionModel? activeQuestion,
    int? userChoiceIndex,
  }) {
    final basePrompt = langCode == 'vi'
        ? '''Bạn là AI Tutor — một trợ lý lập trình Flutter & Dart thông minh, thân thiện và tự nhiên.

Nguyên tắc giao tiếp:
1. Trả lời TRỰC TIẾP, ĐÚNG TRỌNG TÂM câu hỏi. Không chào hỏi rườm rà ở mỗi lượt.
2. Duy trì ngữ cảnh hội thoại: Nắm chắc nội dung các tin nhắn trước. Khi người dùng hỏi nối tiếp ("Tại sao?", "Thế còn...", "Cho ví dụ đi"), hãy hiểu ngay chủ đề đang bàn luận.
3. KHÔNG tự động chia câu trả lời thành các tiêu đề cứng nhắc. Chỉ dùng format học thuật khi người dùng yêu cầu phân tích.
4. Khi minh họa code: Viết code Dart/Flutter chuẩn trong khối ```dart có chú thích ngắn gọn.
5. Thích nghi linh hoạt: Trả lời súc tích khi người dùng muốn ngắn gọn; giải thích sâu khi người dùng muốn đào sâu.
6. Sử dụng Markdown: in đậm từ khóa quan trọng, gạch đầu dòng rõ ràng, code block đẹp mắt.'''
        : '''You are AI Tutor — an intelligent, friendly Flutter & Dart programming companion.

Communication Guidelines:
1. Answer DIRECTLY and concisely. Avoid robotic boilerplate greetings in each turn.
2. Maintain conversation context: Keep track of previous dialogue turns. Seamlessly answer follow-up queries.
3. DO NOT use rigid textbook headings unless specifically asked to analyze a quiz question.
4. Code examples: Provide clean, idiomatic Dart/Flutter code inside ```dart blocks with clear comments.
5. Adaptive response: Be brief when asked for brevity; provide rich real-world examples when asked for details.
6. Format responses with clean Markdown (bold, bullet points, code blocks).''';

    if (activeQuestion == null) return basePrompt;

    final contextText = _buildContextText(
      question: activeQuestion,
      userChoiceIndex: userChoiceIndex,
      langCode: langCode,
    );

    return '$basePrompt\n\n$contextText';
  }

  /// Gửi danh sách tin nhắn và nhận phản hồi dạng SSE stream từ OpenRouter.
  Stream<String> sendMessageStream({
    required List<ChatMessageModel> messages,
    required String langCode,
    QuestionModel? activeQuestion,
    int? userChoiceIndex,
  }) async* {
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw Exception(
        langCode == 'vi'
            ? 'Chưa cấu hình OpenRouter API Key.'
            : 'OpenRouter API Key is not configured.',
      );
    }

    if (model.trim().isEmpty) {
      throw Exception(
        langCode == 'vi'
            ? 'Chưa chọn model OpenRouter. Vui lòng nhập Model ID.'
            : 'OpenRouter model is not configured. Please enter a Model ID.',
      );
    }

    // Giới hạn 20 tin nhắn gần nhất để tránh vượt token limit
    final contextMessages = messages.length > 20
        ? messages.sublist(messages.length - 20)
        : messages;

    // Build messages theo OpenAI format: system + user/assistant
    final requestMessages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': _buildSystemPrompt(
          langCode,
          activeQuestion: activeQuestion,
          userChoiceIndex: userChoiceIndex,
        ),
      },
    ];

    for (final m in contextMessages) {
      if (m.role == 'system' || m.content.trim().isEmpty) continue;
      final role = m.role == 'assistant' ? 'assistant' : 'user';
      requestMessages.add({'role': role, 'content': m.content.trim()});
    }

    if (requestMessages.length <= 1) {
      // Chỉ có system prompt, không có nội dung user
      throw Exception(
        langCode == 'vi'
            ? 'Không có nội dung tin nhắn để gửi tới AI.'
            : 'No message content to send to AI.',
      );
    }

    // Bơm trực tiếp ngữ cảnh câu hỏi vào lượt người dùng đầu tiên trong messages
    // để mô hình luôn nắm bắt câu hỏi ngay cả khi không ưu tiên system prompt
    if (activeQuestion != null) {
      final contextText = _buildContextText(
        question: activeQuestion,
        userChoiceIndex: userChoiceIndex,
        langCode: langCode,
      );
      final firstUserIndex =
          requestMessages.indexWhere((m) => m['role'] == 'user');
      if (firstUserIndex != -1) {
        final currentText =
            requestMessages[firstUserIndex]['content'] as String;
        if (!currentText.contains('[NGỮ CẢNH CÂU HỎI BÀI HỌC HIỆN TẠI]') &&
            !currentText.contains('[CURRENT QUIZ QUESTION CONTEXT]')) {
          requestMessages[firstUserIndex]['content'] =
              '$contextText\n\n---\n[CÂU HỎI / YÊU CẦU CỦA NGƯỜI HỌC]:\n$currentText';
        }
      }
    }

    final url = Uri.parse(_baseUrl);
    final requestBody = jsonEncode({
      'model': model.trim(),
      'messages': requestMessages,
      'stream': true,
      'max_tokens': 2048,
      'temperature': 0.7,
    });

    final request = http.Request('POST', url)
      ..headers.addAll({
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'text/event-stream',
        'HTTP-Referer': 'https://flutter-bilingual.app',
        'X-Title': 'Flutter Song Ngu AI Tutor',
      })
      ..body = requestBody;

    final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
    } on TimeoutException {
      throw Exception(
        langCode == 'vi'
            ? 'Kết nối tới OpenRouter quá thời gian chờ (30s). Vui lòng thử lại.'
            : 'Connection to OpenRouter timed out. Please try again.',
      );
    } catch (e) {
      // Fallback non-streaming cho Flutter Web nếu trình duyệt chặn SSE
      try {
        yield* _sendNonStreaming(
          key: key,
          requestMessages: requestMessages,
          langCode: langCode,
        );
        return;
      } catch (_) {}

      throw Exception(
        langCode == 'vi'
            ? 'Không thể kết nối tới OpenRouter: $e'
            : 'Failed to connect to OpenRouter: $e',
      );
    }

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      _throwFriendlyError(
          streamedResponse.statusCode, errorBody, langCode, model);
    }

    bool gotContent = false;
    await for (final line in streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.isEmpty || line.startsWith(':')) continue;

      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6).trim();
        if (jsonStr == '[DONE]') return;

        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final delta =
                (choices[0] as Map<String, dynamic>)['delta'] as Map?;
            final text = delta?['content'] as String?;
            if (text != null && text.isNotEmpty) {
              gotContent = true;
              yield text;
            }
          }
        } catch (_) {
          // Bỏ qua dòng SSE không đúng định dạng
        }
      }
    }

    if (!gotContent) {
      throw Exception(
        langCode == 'vi'
            ? 'OpenRouter không trả về nội dung. Vui lòng kiểm tra Model ID.'
            : 'OpenRouter returned no content. Please check your Model ID.',
      );
    }
  }

  /// Gọi non-streaming (fallback cho Flutter Web nếu SSE bị chặn).
  Stream<String> _sendNonStreaming({
    required String key,
    required List<Map<String, dynamic>> requestMessages,
    required String langCode,
  }) async* {
    final url = Uri.parse(_baseUrl);
    final resp = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json; charset=utf-8',
            'HTTP-Referer': 'https://flutter-bilingual.app',
            'X-Title': 'Flutter Song Ngu AI Tutor',
          },
          body: jsonEncode({
            'model': model.trim(),
            'messages': requestMessages,
            'stream': false,
            'max_tokens': 2048,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      _throwFriendlyError(
          resp.statusCode, utf8.decode(resp.bodyBytes), langCode, model);
    }

    final data =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices != null && choices.isNotEmpty) {
      final content =
          (choices[0]['message'] as Map?)?['content'] as String? ?? '';
      if (content.isNotEmpty) {
        yield content;
        return;
      }
    }

    throw Exception(
      langCode == 'vi'
          ? 'OpenRouter không trả về nội dung.'
          : 'OpenRouter returned no content.',
    );
  }

  /// Parse và ném lỗi thân thiện từ response OpenRouter.
  void _throwFriendlyError(
      int statusCode, String body, String langCode, String modelId) {
    String message = body;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final errObj = json['error'];
      if (errObj is Map) {
        message = (errObj['message'] as String?) ?? body;
      } else if (errObj is String) {
        message = errObj;
      }
    } catch (_) {}

    debugPrint('OpenRouter Error $statusCode: $message');

    final isVi = langCode == 'vi';
    String friendly;

    if (statusCode == 401 ||
        message.contains('No auth credentials') ||
        message.contains('invalid api key')) {
      friendly = isVi
          ? 'OpenRouter API Key không hợp lệ hoặc hết hạn. Vui lòng kiểm tra lại (bấm 🔑).'
          : 'Invalid or expired OpenRouter API Key. Please check it (tap 🔑).';
    } else if (statusCode == 403) {
      friendly = isVi
          ? 'Tài khoản không có quyền truy cập model "$modelId" (403). Kiểm tra giới hạn tài khoản OpenRouter.'
          : 'No permission to access model "$modelId" (403). Check your OpenRouter account limits.';
    } else if (statusCode == 404 || message.contains('model')) {
      friendly = isVi
          ? 'Model "$modelId" không tồn tại hoặc không khả dụng (404). Vui lòng kiểm tra lại Model ID.'
          : 'Model "$modelId" not found or unavailable (404). Please verify the Model ID.';
    } else if (statusCode == 429 ||
        message.toLowerCase().contains('rate limit') ||
        message.toLowerCase().contains('quota')) {
      friendly = isVi
          ? 'Đã vượt hạn mức (Rate Limit 429). Vui lòng đợi 1 phút rồi thử lại.'
          : 'Rate limit exceeded (429). Please wait a minute and try again.';
    } else if (message.toLowerCase().contains('insufficient')) {
      friendly = isVi
          ? 'Tài khoản OpenRouter chưa có credits. Vui lòng nạp credits hoặc dùng model Free Tier.'
          : 'Insufficient OpenRouter credits. Please top up or use a Free Tier model.';
    } else {
      friendly = isVi
          ? 'Lỗi OpenRouter ($statusCode): $message'
          : 'OpenRouter error ($statusCode): $message';
    }

    throw Exception(friendly);
  }
}
