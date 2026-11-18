import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message_model.dart';

/// Kết quả stream từ remote datasource: mỗi chunk là một phần văn bản AI.
class ChatRemoteDataSource {
  /// Base URL của backend proxy (ví dụ: https://your-worker.workers.dev).
  /// Không chứa API key ở đây — key được giữ trong Worker secret.
  final String baseUrl;

  const ChatRemoteDataSource({required this.baseUrl});

  /// Gửi tin nhắn lên proxy và lắng nghe stream phản hồi từ Gemini.
  ///
  /// Trả về [Stream<String>] mỗi khi có một đoạn văn bản mới từ AI.
  /// Ném lỗi nếu proxy không phản hồi hoặc bị ngắt kết nối.
  Stream<String> sendMessageStream({
    required List<ChatMessageModel> messages,
    required String langCode,
  }) async* {
    final url = Uri.parse('$baseUrl/api/chat');

    final body = jsonEncode({
      'messages': messages.map((m) => m.toJson()).toList(),
      'langCode': langCode,
    });

    try {
      final request = http.Request('POST', url)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = body;

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception(
          'Proxy lỗi (${streamedResponse.statusCode}): $errorBody',
        );
      }

      await for (final line in streamedResponse.stream.transform(
        utf8.decoder,
      ).transform(const LineSplitter())) {
        if (line.isEmpty || line.startsWith(':')) continue;

        // Parse SSE data: "data: {...}"
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6);
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            if (data['done'] == true) {
              // Kết thúc stream
              return;
            }
            final chunk = data['chunk'] as String?;
            if (chunk != null && chunk.isNotEmpty) {
              yield chunk;
            }
          } catch (_) {
            // Bỏ qua dòng SSE không phân tích được
          }
        }
      }
    } on TimeoutException {
      throw Exception('Kết nối proxy quá thời gian chờ. Vui lòng thử lại.');
    } on http.ClientException catch (e) {
      throw Exception('Lỗi kết nối proxy: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi gọi AI: $e');
    }
  }
}
