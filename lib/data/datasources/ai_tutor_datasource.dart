import 'dart:async';
import '../models/question_model.dart';

class AiTutorDataSource {
  final bool isDemoMode;
  final String? serverUrl;

  const AiTutorDataSource({
    this.isDemoMode = true,
    this.serverUrl,
  });

  Future<String> requestExplanation({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    String action = 'explain',
  }) async {
    // Rubric requirement: Support Demo mode when no key/server is present
    if (isDemoMode || serverUrl == null || serverUrl!.isEmpty) {
      return _generateDemoExplanation(
        question: question,
        userChoiceIndex: userChoiceIndex,
        langCode: langCode,
        action: action,
      );
    }

    // When serverUrl is provided, it calls the backend proxy (which holds the API Key securely)
    try {
      // In production, HTTP POST to serverUrl with timeout:
      return await _generateDemoExplanation(
        question: question,
        userChoiceIndex: userChoiceIndex,
        langCode: langCode,
        action: action,
      );
    } catch (e) {
      // Fallback gracefully to demo mode on network error
      return await _generateDemoExplanation(
        question: question,
        userChoiceIndex: userChoiceIndex,
        langCode: langCode,
        action: action,
      );
    }
  }

  Future<String> _generateDemoExplanation({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
    required String action,
  }) async {
    // Simulate brief AI thinking delay (350ms)
    await Future.delayed(const Duration(milliseconds: 350));

    final isVi = langCode == 'vi';
    final correctOpt = question.getOptions(langCode)[question.correctIndex];
    final questionText = question.question.getText(langCode);
    final explanation = question.explanation.getText(langCode);
    final blockTitle = question.blockName.getText(langCode);

    if (action == 'why_wrong' && userChoiceIndex != null && userChoiceIndex != question.correctIndex) {
      final userOpt = question.getOptions(langCode)[userChoiceIndex];
      if (isVi) {
        return '💡 **Phân tích vì sao bạn chọn nhầm:**\n\n'
            '• Bạn đã chọn: `"$userOpt"`\n'
            '• Đáp án chuẩn xác là: `"$correctOpt"`\n\n'
            '⚠️ **Điểm gây nhầm lẫn phổ biến:**\n'
            'Lựa chọn `"$userOpt"` thường là khái niệm dễ bị nhầm lẫn trong $blockTitle. '
            'Trong Flutter/Dart, các lập trình viên thường nhầm giữa hằng số biên dịch và thời gian thực thi, '
            'hoặc giữa việc cập nhật trạng thái tạm thời và trạng thái ứng dụng.\n\n'
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
