import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/chat_message_model.dart';

/// Datasource gọi trực tiếp Google Gemini API (không cần backend/proxy).
/// Sử dụng endpoint chính thức: https://generativelanguage.googleapis.com
class GeminiDirectDataSource {
  final String apiKey;
  final String model;

  const GeminiDirectDataSource({
    required this.apiKey,
    this.model = 'gemini-1.5-flash',
  });

  bool get hasKey => apiKey.trim().isNotEmpty;

  /// Gửi danh sách tin nhắn và nhận phản hồi dạng SSE stream trực tiếp từ Gemini.
  Stream<String> sendMessageStream({
    required List<ChatMessageModel> messages,
    required String langCode,
  }) async* {
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw Exception(
        langCode == 'vi'
            ? 'Chưa cấu hình Gemini API Key. Vui lòng nhập API Key để chat với AI.'
            : 'Gemini API Key is not configured. Please provide an API Key to chat with AI.',
      );
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$key',
    );

    final systemPrompt = langCode == 'vi'
        ? '''Bạn là AI Tutor — một trợ lý lập trình Flutter & Dart thông minh, thân thiện và tự nhiên (tương tự trải nghiệm ChatGPT).

Nguyên tắc giao tiếp:
1. Trả lời TRỰC TIẾP, ĐÚNG TRỌNG TÂM câu hỏi. Không chào hỏi rườm rà ở mỗi lượt, không nhắc lại nguyên văn câu hỏi của người dùng.
2. Duy trì ngữ cảnh hội thoại: Nắm chắc nội dung các tin nhắn trước. Khi người dùng hỏi nối tiếp ("Tại sao?", "Thế còn...", "Cho ví dụ đi", "Nói ngắn gọn hơn", "Chưa hiểu lắm"), hãy hiểu ngay chủ đề đang bàn luận để đối thoại liền mạch.
3. KHÔNG tự động chia câu trả lời thành các tiêu đề cứng nhắc như "Khối kiến thức / Đáp án đúng / Bản chất kỹ thuật". Chỉ dùng format học thuật khi người dùng yêu cầu phân tích đề thi hoặc giải bài tập.
4. Khi minh họa code: Viết code Dart/Flutter chuẩn Clean Code trong khối ```dart có chú thích ngắn gọn, dễ hiểu.
5. Thích nghi linh hoạt: Trả lời súc tích khi người dùng muốn ngắn gọn; giải thích sâu sắc, kèm ví dụ thực tế khi người dùng muốn đào sâu.
6. Sử dụng Markdown tinh tế: in đậm từ khóa quan trọng, gạch đầu dòng rõ ràng, code block đẹp mắt.'''
        : '''You are AI Tutor — an intelligent, friendly, and natural Flutter & Dart programming companion (similar to ChatGPT).

Communication Guidelines:
1. Answer DIRECTLY and concisely to the point. Avoid robotic boilerplate greetings in each turn, and do not repeat the user's prompt.
2. Maintain conversation context: Keep track of previous dialogue turns. Seamlessly answer follow-up queries ("Why?", "What about...", "Show an example", "Make it simpler").
3. DO NOT use rigid textbook headings (e.g. "Knowledge Block / Correct Answer / Technical Breakdown") unless specifically asked to analyze a quiz question.
4. Code examples: Provide clean, idiomatic Dart/Flutter code inside ```dart blocks with clear comments.
5. Adaptive response: Be brief when asked for brevity; provide rich real-world examples when asked for details.
6. Format responses with clean Markdown (bold, bullet points, code blocks) for effortless readability.''';

    // Giới hạn context window: giữ tối đa 20 tin nhắn gần nhất để tránh vượt token
    final contextMessages = messages.length > 20
        ? messages.sublist(messages.length - 20)
        : messages;

    final contents = <Map<String, dynamic>>[];
    for (final m in contextMessages) {
      if (m.role == 'system' || m.content.trim().isEmpty) continue;
      final role = m.role == 'assistant' ? 'model' : 'user';

      if (contents.isNotEmpty && contents.last['role'] == role) {
        final parts = contents.last['parts'] as List;
        parts.add({'text': m.content.trim()});
      } else {
        contents.add({
          'role': role,
          'parts': [
            {'text': m.content.trim()}
          ],
        });
      }
    }

    if (contents.isEmpty) {
      throw Exception(
        langCode == 'vi'
            ? 'Không có nội dung tin nhắn để gửi tới AI.'
            : 'No message content to send to AI.',
      );
    }

    // Gemini yêu cầu lượt hội thoại đầu tiên bắt buộc phải là 'user'
    while (contents.isNotEmpty && contents.first['role'] != 'user') {
      contents.removeAt(0);
    }

    final requestBody = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      },
    });

    final request = http.Request('POST', url)
      ..headers.addAll({
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'text/event-stream',
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
            ? 'Kết nối tới Gemini quá thời gian chờ (30s). Vui lòng thử lại.'
            : 'Connection to Gemini timed out. Please try again.',
      );
    } catch (e) {
      // Dự phòng cho Flutter Web nếu trình duyệt chặn SSE stream: gọi non-streaming POST
      try {
        final fallbackUrl = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
        );
        final resp = await http.post(
          fallbackUrl,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: requestBody,
        ).timeout(const Duration(seconds: 30));

        if (resp.statusCode == 200) {
          final data =
              jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']?['parts'] as List?;
            if (parts != null) {
              for (final part in parts) {
                final text = part['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
              return;
            }
          }
          throw Exception(
            langCode == 'vi'
                ? 'AI không trả về nội dung.'
                : 'No content returned from AI.',
          );
        } else {
          _throwFriendlyError(resp.statusCode, resp.body, langCode);
        }
      } catch (fallbackError) {
        if (fallbackError is Exception &&
            fallbackError.toString().contains('Gemini')) {
          rethrow;
        }
      }

      throw Exception(
        langCode == 'vi'
            ? 'Không thể kết nối tới Google AI: $e'
            : 'Failed to connect to Google AI: $e',
      );
    }

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      _throwFriendlyError(streamedResponse.statusCode, errorBody, langCode);
    }

    await for (final line in streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.isEmpty || line.startsWith(':')) continue;

      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6).trim();
        if (jsonStr == '[DONE]') return;

        try {
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final candidate = candidates[0] as Map<String, dynamic>;
            final content = candidate['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            if (parts != null) {
              for (final part in parts) {
                final text = part['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
            }
          }
        } catch (_) {
          // Bỏ qua dòng json SSE không đúng định dạng
        }
      }
    }
  }

  void _throwFriendlyError(int statusCode, String errorBody, String langCode) {
    String friendlyMessage = errorBody;
    try {
      final errJson = jsonDecode(errorBody);
      final rawMsg = errJson['error']?['message'] as String?;
      final status = errJson['error']?['status'] as String?;
      if (rawMsg != null) {
        if (rawMsg.contains('API key not valid') ||
            status == 'API_KEY_INVALID' ||
            rawMsg.contains('API_KEY_INVALID')) {
          friendlyMessage = langCode == 'vi'
              ? 'API Key không hợp lệ. Vui lòng kiểm tra lại Gemini API Key của bạn (bấm biểu tượng 🔑 ở góc trên để nhập lại).'
              : 'Invalid API Key. Please verify your Gemini API Key.';
        } else if (rawMsg.contains('Resource has been exhausted') ||
            statusCode == 429 ||
            status == 'RESOURCE_EXHAUSTED') {
          friendlyMessage = langCode == 'vi'
              ? 'Đã vượt quá hạn mức miễn phí (Rate Limit 429). Vui lòng đợi 1 phút rồi thử lại.'
              : 'Rate limit exceeded (429). Please wait a minute and try again.';
        } else if (rawMsg.contains('PERMISSION_DENIED') || statusCode == 403) {
          friendlyMessage = langCode == 'vi'
              ? 'Tài khoản chưa được cấp quyền dùng Gemini API hoặc bị giới hạn vùng (403).'
              : 'Permission denied for Gemini API (403).';
        } else {
          friendlyMessage = rawMsg;
        }
      }
    } catch (_) {}

    throw Exception(
      '${langCode == 'vi' ? 'Lỗi Gemini' : 'Gemini error'} ($statusCode): $friendlyMessage',
    );
  }

  /// Gọi 1 lần (non-streaming), dùng cho popup/sheet giải thích nhanh.
  Future<String> generateSingleResponse({
    required String prompt,
    required String langCode,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw Exception('Chưa cấu hình API Key');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
    );

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 1024,
            },
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      throw Exception('Gemini lỗi (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final candidates = data['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final parts = candidates[0]?['content']?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        return parts[0]['text'] ?? '';
      }
    }

    throw Exception('Không nhận được nội dung từ Gemini');
  }
}
