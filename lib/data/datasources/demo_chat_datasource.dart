import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/question_model.dart';

/// Fallback chat offline khi chưa có backend proxy.
/// Tìm kiếm từ khóa trong questions.json và trả lời song ngữ.
class DemoChatDataSource {
  const DemoChatDataSource();

  /// Trả lời dựa trên dữ liệu câu hỏi có sẵn.
  /// Nếu không tìm thấy, trả lời lịch sự đề xuất người dùng hỏi về câu hỏi trong app.
  Future<String> getDemoAnswer({
    required String userMessage,
    required String langCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final isVi = langCode == 'vi';
    final jsonString = await rootBundle.loadString('assets/data/questions.json');

    try {
      final List<dynamic> data = jsonDecode(jsonString);
      final bestMatch = _findBestMatch(data, userMessage, langCode);

      if (bestMatch != null) {
        return _formatMatchAnswer(bestMatch, isVi);
      }
    } catch (_) {
      // Bỏ qua lỗi parse JSON
    }

    // Câu trả lời mặc định khi không tìm thấy dữ liệu phù hợp
    if (isVi) {
      return '''🤖 **Trợ lý AI (chế độ demo offline)**

Tôi hiện đang chạy ở chế độ demo và chỉ có dữ liệu câu hỏi trắc nghiệm Flutter trong ứng dụng.

Bạn có thể hỏi tôi về:
• Các câu hỏi trắc nghiệm Flutter/Dart trong app
• Giải thích đáp án đúng/sai
• Mẹo ghi nhớ kiến thức thi

Ngoài phạm vi dữ liệu có sẵn, tôi chưa có kết nối đến AI thật. Bạn có thể cấu hình backend proxy để tôi kết nối Gemini và trả lời tự do hơn.''';
    } else {
      return '''🤖 **AI Tutor (demo offline mode)**

I am currently running in demo mode and only have Flutter quiz questions from the app.

You can ask me about:
• Flutter/Dart multiple-choice questions in the app
• Explanations for correct/incorrect answers
• Exam memory tips

Outside the available data, I don't have a real AI connection yet. Configure a backend proxy to connect to Gemini and chat more freely.''';
    }
  }

  QuestionModel? _findBestMatch(
    List<dynamic> data,
    String userMessage,
    String langCode,
  ) {
    final keywords = userMessage.toLowerCase().split(RegExp(r'\s+'));
    QuestionModel? best;
    int bestScore = 0;

    for (final item in data) {
      try {
        final q = QuestionModel.fromJson(item);
        final questionText = q.question.getText(langCode).toLowerCase();
        final blockName = q.blockName.getText(langCode).toLowerCase();
        final explanation = q.explanation.getText(langCode).toLowerCase();
        final options = q.getOptions(langCode).join(' ').toLowerCase();
        final allText = '$questionText $blockName $explanation $options';

        int score = 0;
        for (final kw in keywords) {
          if (kw.length > 2 && allText.contains(kw)) {
            score++;
          }
        }

        if (score > bestScore) {
          bestScore = score;
          best = q;
        }
      } catch (_) {
        continue;
      }
    }

    return bestScore > 0 ? best : null;
  }

  String _formatMatchAnswer(QuestionModel q, bool isVi) {
    final correctOpt = q.getOptions(isVi ? 'vi' : 'en')[q.correctIndex];
    final questionText = q.question.getText(isVi ? 'vi' : 'en');
    final explanation = q.explanation.getText(isVi ? 'vi' : 'en');
    final blockTitle = q.blockName.getText(isVi ? 'vi' : 'en');

    if (isVi) {
      return '''🎓 **Gia sư AI (demo) phân tích câu hỏi:**

**Câu hỏi:** $questionText
**Khối kiến thức:** $blockTitle
**Đáp án đúng:** $correctOpt

**Giải thích:** $explanation

_(Chế độ demo: chỉ trả lời dựa trên dữ liệu câu hỏi có sẵn trong app.)_''';
    } else {
      return '''🎓 **AI Tutor (demo) analysis:**

**Question:** $questionText
**Knowledge Block:** $blockTitle
**Correct Answer:** $correctOpt

**Explanation:** $explanation

_(Demo mode: answers based only on available quiz data in the app.)_''';
    }
  }
}
