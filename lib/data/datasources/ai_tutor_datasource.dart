import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/ai_config.dart';
import '../models/question_model.dart';
import 'gemini_direct_datasource.dart';

class AiTutorDataSource {
  final bool isDemoMode;
  final String? serverUrl;

  const AiTutorDataSource({
    this.isDemoMode = false,
    this.serverUrl,
  });

  Future<String> requestExplanation({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    String action = 'explain',
  }) async {
    // 1. Thử gọi trực tiếp Gemini nếu đã có API Key trong máy
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(AiConfig.prefsApiKey) ?? AiConfig.envApiKey;
      if (key.trim().isNotEmpty) {
        final gemini = GeminiDirectDataSource(apiKey: key.trim());
        final isVi = langCode == 'vi';
        final block = question.blockName.getText(langCode);
        final qText = question.question.getText(langCode);
        final correct = question.getOptions(langCode)[question.correctIndex];
        final userChoice = userChoiceIndex != null &&
                userChoiceIndex < question.getOptions(langCode).length
            ? question.getOptions(langCode)[userChoiceIndex]
            : null;

        String actionPrompt = '';
        if (action == 'why_wrong' && userChoice != null) {
          actionPrompt = isVi
              ? 'Học viên đã chọn nhầm đáp án "$userChoice" thay vì đáp án đúng "$correct". Hãy phân tích vì sao "$userChoice" là lựa chọn sai, bẫy nhầm lẫn thường gặp và cách phân biệt.'
              : 'Student mistakenly chose "$userChoice" instead of "$correct". Explain why "$userChoice" is wrong, the common trap, and how to distinguish.';
        } else if (action == 'code_example') {
          actionPrompt = isVi
              ? 'Hãy đưa ra ví dụ code Dart/Flutter thực tế (ngắn gọn, chuẩn Clean Code) minh họa kiến thức trong câu hỏi này.'
              : 'Provide a clean, realistic Dart/Flutter code snippet illustrating this concept.';
        } else if (action == 'memory_tip') {
          actionPrompt = isVi
              ? 'Hãy đưa ra 1 mẹo ghi nhớ nhanh hoặc quy tắc vàng khi làm bài thi trắc nghiệm về phần này.'
              : 'Provide a quick exam tip or rule of thumb for this topic.';
        } else {
          actionPrompt = isVi
              ? 'Hãy phân tích bản chất câu hỏi, giải thích vì sao "$correct" là đáp án chuẩn xác nhất.'
              : 'Break down the question and explain why "$correct" is the exact right answer.';
        }

        final prompt = isVi
            ? 'Bạn là Gia sư AI Flutter chuyên nghiệp. Hãy trả lời ngắn gọn (dưới 200 từ) bằng Markdown:\n\n'
                '• Khối kiến thức: $block\n'
                '• Câu hỏi: $qText\n'
                '• Yêu cầu: $actionPrompt'
            : 'You are an AI Flutter Tutor. Answer concisely (under 200 words) using Markdown:\n\n'
                '• Topic: $block\n'
                '• Question: $qText\n'
                '• Request: $actionPrompt';

        final result = await gemini.generateSingleResponse(
          prompt: prompt,
          langCode: langCode,
        );
        if (result.trim().isNotEmpty) {
          return result;
        }
      }
    } catch (_) {
      // Tự động chuyển xuống fallback offline nếu có lỗi hoặc mất mạng
    }

    // 2. Fallback offline: dùng dữ liệu có sẵn của câu hỏi
    return _generateDemoExplanation(
      question: question,
      userChoiceIndex: userChoiceIndex,
      langCode: langCode,
      action: action,
    );
  }

  Future<String> _generateDemoExplanation({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    required String action,
  }) async {
    // Độ trễ nhẹ mô phỏng phản hồi (200ms)
    await Future.delayed(const Duration(milliseconds: 200));

    final isVi = langCode == 'vi';
    final correctOpt = question.getOptions(langCode)[question.correctIndex];
    final questionText = question.question.getText(langCode);
    final explanation = question.explanation.getText(langCode);
    final blockTitle = question.blockName.getText(langCode);

    if (action == 'why_wrong' &&
        userChoiceIndex != null &&
        userChoiceIndex != question.correctIndex) {
      final userOpt = question.getOptions(langCode)[userChoiceIndex];
      if (isVi) {
        return '💡 **Phân tích vì sao bạn chọn nhầm:**\n\n'
            '• Bạn đã chọn: `"$userOpt"`\n'
            '• Đáp án chuẩn xác là: `"$correctOpt"`\n\n'
            '⚠️ **Điểm gây nhầm lẫn phổ biến:**\n'
            'Lựa chọn `"$userOpt"` thường là khái niệm dễ bị nhầm lẫn trong chủ đề $blockTitle. '
            'Trong Flutter/Dart, các lập trình viên thường nhầm giữa hằng số biên dịch và thời gian thực thi, '
            'hoặc giữa việc cập nhật trạng thái tạm thời và vòng đời widget.\n\n'
            '📌 **Bản chất cốt lõi:**\n'
            '$explanation';
      } else {
        return '💡 **Why your answer was incorrect:**\n\n'
            '• Your selection: `"$userOpt"`\n'
            '• Correct answer: `"$correctOpt"`\n\n'
            '⚠️ **Common Misconception:**\n'
            'Option `"$userOpt"` is a frequent trap in $blockTitle. '
            'In Flutter & Dart architecture, developers often conflate runtime evaluation with compile-time immutability, '
            'or widget recreation with element lifecycle.\n\n'
            '📌 **Core takeaway:**\n'
            '$explanation';
      }
    }

    if (action == 'code_example') {
      if (isVi) {
        return '💻 **Ví dụ mã nguồn thực tế:**\n\n'
            '```dart\n'
            '// Minh họa kiến thức trong: $blockTitle\n'
            'void main() {\n'
            '  // Đáp án đúng áp dụng nguyên lý:\n'
            '  // $correctOpt\n'
            '  print("Kiểm tra chuẩn: $explanation");\n'
            '}\n'
            '```\n\n'
            '👉 **Mẹo lập trình:** Luôn tuân thủ quy tắc kiến trúc Flutter: tách biệt dữ liệu khỏi giao diện và quản lý vòng đời chặt chẽ.';
      } else {
        return '💻 **Practical Code Example:**\n\n'
            '```dart\n'
            '// Concept illustrated in: $blockTitle\n'
            'void main() {\n'
            '  // Correct usage applying the principle:\n'
            '  // $correctOpt\n'
            '  print("Standard check: $explanation");\n'
            '}\n'
            '```\n\n'
            '👉 **Best Practice Tip:** Always follow Flutter architectural guidelines: isolate data logic from widgets and maintain clean lifecycle disposal.';
      }
    }

    if (action == 'memory_tip') {
      if (isVi) {
        return '⚡ **Mẹo ghi nhớ nhanh để đi thi:**\n\n'
            '🔑 **Từ khóa vàng:** Gắn liền câu hỏi `"$questionText"` với cụm từ `"$correctOpt"`.\n'
            '• Khi gặp câu hỏi về $blockTitle, hãy nhớ quy tắc: $explanation\n'
            '• Không bao giờ gọi tính toán nặng hay I/O trong hàm `build()`.';
      } else {
        return '⚡ **Quick Exam Memory Tip:**\n\n'
            '🔑 **Golden Keyword:** Associate `"$questionText"` with `"$correctOpt"`.\n'
            '• When encountering questions on $blockTitle, remember: $explanation\n'
            '• Never perform heavy computation or I/O inside `build()`.';
      }
    }

    // Default 'explain'
    if (isVi) {
      return '🎓 **Gia sư AI Flutter phân tích chuyên sâu:**\n\n'
          '**1. Khối kiến thức:** $blockTitle\n'
          '**2. Đáp án đúng:** `$correctOpt`\n\n'
          '**3. Giải thích chi tiết:**\n'
          '$explanation\n\n'
          '**4. Tài liệu tham khảo chính thức:**\n'
          'Bạn có thể tham khảo thêm tại tài liệu chính thức: `flutter.dev/docs` mục $blockTitle.';
    } else {
      return '🎓 **AI Flutter Tutor In-Depth Breakdown:**\n\n'
          '**1. Knowledge Block:** $blockTitle\n'
          '**2. Correct Answer:** `$correctOpt`\n\n'
          '**3. Detailed Explanation:**\n'
          '$explanation\n\n'
          '**4. Official Documentation Reference:**\n'
          'Consult the official Flutter docs at `flutter.dev/docs` under $blockTitle.';
    }
  }
}
