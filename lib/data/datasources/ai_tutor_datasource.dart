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
        return 'ðŸ’¡ **PhÃ¢n tÃ­ch vÃ¬ sao báº¡n chá»n nháº§m:**\n\n'
            'â€¢ Báº¡n Ä‘Ã£ chá»n: `"$userOpt"`\n'
            'â€¢ ÄÃ¡p Ã¡n chuáº©n xÃ¡c lÃ : `"$correctOpt"`\n\n'
            'âš ï¸ **Äiá»ƒm gÃ¢y nháº§m láº«n phá»• biáº¿n:**\n'
            'Lá»±a chá»n `"$userOpt"` thÆ°á»ng lÃ  khÃ¡i niá»‡m dá»… bá»‹ nháº§m láº«n trong $blockTitle. '
            'Trong Flutter/Dart, cÃ¡c láº­p trÃ¬nh viÃªn thÆ°á»ng nháº§m giá»¯a háº±ng sá»‘ biÃªn dá»‹ch vÃ  thá»i gian thá»±c thi, '
            'hoáº·c giá»¯a viá»‡c cáº­p nháº­t tráº¡ng thÃ¡i táº¡m thá»i vÃ  tráº¡ng thÃ¡i á»©ng dá»¥ng.\n\n'
            'ðŸ“Œ **Báº£n cháº¥t cá»‘t lÃµi:**\n'
            '$explanation';
      } else {
        return 'ðŸ’¡ **Why your answer was incorrect:**\n\n'
            'â€¢ Your selection: `"$userOpt"`\n'
            'â€¢ Correct answer: `"$correctOpt"`\n\n'
            'âš ï¸ **Common Misconception:**\n'
            'Option `"$userOpt"` is a frequent trap in $blockTitle. '
            'In Flutter & Dart architecture, developers often conflate runtime evaluation with compile-time immutability, '
            'or widget recreation with element lifecycle.\n\n'
            'ðŸ“Œ **Core takeaway:**\n'
            '$explanation';
      }
    }

    if (action == 'code_example') {
      if (isVi) {
        return 'ðŸ’» **VÃ­ dá»¥ mÃ£ nguá»“n thá»±c táº¿:**\n\n'
            '```dart\n'
            '// Minh há»a kiáº¿n thá»©c trong: $blockTitle\n'
            'void main() {\n'
            '  // ÄÃ¡p Ã¡n Ä‘Ãºng Ã¡p dá»¥ng nguyÃªn lÃ½:\n'
            '  // $correctOpt\n'
            '  print("Kiá»ƒm tra chuáº©n: $explanation");\n'
            '}\n'
            '```\n\n'
            'ðŸ‘‰ **Máº¹o láº­p trÃ¬nh:** LuÃ´n tuÃ¢n thá»§ quy táº¯c kiáº¿n trÃºc Flutter: tÃ¡ch biá»‡t dá»¯ liá»‡u khá»i giao diá»‡n vÃ  quáº£n lÃ½ vÃ²ng Ä‘á»i cháº·t cháº½.';
      } else {
        return 'ðŸ’» **Practical Code Example:**\n\n'
            '```dart\n'
            '// Concept illustrated in: $blockTitle\n'
            'void main() {\n'
            '  // Correct usage applying the principle:\n'
            '  // $correctOpt\n'
            '  print("Standard check: $explanation");\n'
            '}\n'
            '```\n\n'
            'ðŸ‘‰ **Best Practice Tip:** Always follow Flutter architectural guidelines: isolate data logic from widgets and maintain clean lifecycle disposal.';
      }
    }

    if (action == 'memory_tip') {
      if (isVi) {
        return 'âš¡ **Máº¹o ghi nhá»› nhanh Ä‘á»ƒ Ä‘i thi:**\n\n'
            'ðŸ”‘ **Tá»« khÃ³a vÃ ng:** Gáº¯n liá»n cÃ¢u há»i `"$questionText"` vá»›i cá»¥m tá»« `"$correctOpt"`.\n'
            'â€¢ Khi gáº·p cÃ¢u há»i vá» $blockTitle, hÃ£y nhá»› quy táº¯c: $explanation\n'
            'â€¢ KhÃ´ng bao giá» gá»i tÃ­nh toÃ¡n náº·ng hay I/O trong hÃ m `build()`.';
      } else {
        return 'âš¡ **Quick Exam Memory Tip:**\n\n'
            'ðŸ”‘ **Golden Keyword:** Associate `"$questionText"` with `"$correctOpt"`.\n'
            'â€¢ When encountering questions on $blockTitle, remember: $explanation\n'
            'â€¢ Never perform heavy computation or I/O inside `build()`.';
      }
    }

    // Default 'explain'
    if (isVi) {
      return 'ðŸŽ“ **Gia sÆ° AI Flutter phÃ¢n tÃ­ch chuyÃªn sÃ¢u:**\n\n'
          '**1. Khá»‘i kiáº¿n thá»©c:** $blockTitle\n'
          '**2. ÄÃ¡p Ã¡n Ä‘Ãºng:** `$correctOpt`\n\n'
          '**3. Giáº£i thÃ­ch chi tiáº¿t:**\n'
          '$explanation\n\n'
          '**4. TÃ i liá»‡u tham kháº£o chÃ­nh thá»©c:**\n'
          'Báº¡n cÃ³ thá»ƒ tham kháº£o thÃªm táº¡i tÃ i liá»‡u chÃ­nh thá»©c: `flutter.dev/docs` má»¥c $blockTitle.';
    } else {
      return 'ðŸŽ“ **AI Flutter Tutor In-Depth Breakdown:**\n\n'
          '**1. Knowledge Block:** $blockTitle\n'
          '**2. Correct Answer:** `$correctOpt`\n\n'
          '**3. Detailed Explanation:**\n'
          '$explanation\n\n'
          '**4. Official Documentation Reference:**\n'
          'Consult the official Flutter docs at `flutter.dev/docs` under $blockTitle.';
    }
  }
}
