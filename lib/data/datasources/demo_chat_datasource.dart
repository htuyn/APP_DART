import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/question_model.dart';

/// Fallback chat offline khi chưa có kết nối Internet hoặc chưa cấu hình API Key.
/// Trả lời tự nhiên, thân thiện dựa trên dữ liệu câu hỏi trong ứng dụng.
class DemoChatDataSource {
  const DemoChatDataSource();

  /// Định dạng phân tích tự nhiên cho một câu hỏi cụ thể đã biết trước.
  String formatQuestionAnswer({
    required QuestionModel question,
    int? userChoiceIndex,
    required String langCode,
  }) {
    final isVi = langCode == 'vi';
    final block = question.blockName.getText(langCode);
    final correctOpt = question.getOptions(langCode)[question.correctIndex];
    final explanation = question.explanation.getText(langCode);

    if (isVi) {
      final userChoiceText = userChoiceIndex != null &&
              userChoiceIndex != question.correctIndex
          ? '\n\nỞ câu này, bạn đã chọn `${question.getOptions(langCode)[userChoiceIndex]}`. Lựa chọn này chưa chính xác vì đây là khái niệm dễ gây nhầm lẫn trong chủ đề $block.'
          : '';

      return '''Đáp án chuẩn xác của câu hỏi này là: **`$correctOpt`**.$userChoiceText

$explanation

💡 **Mẹo ghi nhớ:**
Trong chủ đề **$block**, hãy ghi nhớ nguyên lý: "$correctOpt" để không bị bẫy ở các câu hỏi tương tự nhé!''';
    } else {
      final userChoiceText = userChoiceIndex != null &&
              userChoiceIndex != question.correctIndex
          ? '\n\nIn this question, you selected `${question.getOptions(langCode)[userChoiceIndex]}`. This option was incorrect due to a common trap in $block.'
          : '';

      return '''The correct answer is: **`$correctOpt`**.$userChoiceText

$explanation

💡 **Helpful Tip:**
For **$block**, always keep in mind: "$correctOpt" to easily tackle similar questions!''';
    }
  }

  /// Trả lời dựa trên dữ liệu câu hỏi có sẵn hoặc tìm kiếm từ khóa.
  Future<String> getDemoAnswer({
    required String userMessage,
    required String langCode,
    QuestionModel? activeQuestion,
    int? userChoiceIndex,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final isVi = langCode == 'vi';
    final cleanMsg = userMessage.trim().toLowerCase();

    // 1. Nhận diện các câu chào hỏi thông thường
    final isGreeting = cleanMsg == 'hi' ||
        cleanMsg == 'hello' ||
        cleanMsg == 'hey' ||
        cleanMsg == 'xin chào' ||
        cleanMsg == 'xin chao' ||
        cleanMsg == 'chào bạn' ||
        cleanMsg == 'chao ban' ||
        cleanMsg == 'chào ai' ||
        cleanMsg == 'alo' ||
        cleanMsg.startsWith('hi ') ||
        cleanMsg.startsWith('hello ') ||
        cleanMsg.startsWith('xin chào') ||
        cleanMsg.startsWith('chào ');

    if (isGreeting) {
      if (isVi) {
        return '''Xin chào bạn! 👋 Mình là AI Tutor đồng hành cùng bạn học Flutter & Dart.

Hôm nay bạn muốn tìm hiểu điều gì?
- 💡 Giải thích một khái niệm (Widget, BuildContext, State, Provider, Stream...)
- 📝 Phân tích câu hỏi trắc nghiệm hoặc bài học
- 💻 Viết ví dụ code thực tế
- 🛠️ Hướng dẫn gỡ lỗi (debug) trong Flutter

*Mẹo: Bạn có thể bấm biểu tượng 🔑 trên thanh công cụ để nhập Gemini API Key miễn phí và trò chuyện trực tiếp không giới hạn nhé!*''';
      } else {
        return '''Hello! 👋 I am your Flutter & Dart AI Tutor.

What would you like to explore today?
- 💡 Explain a Flutter concept (Widget, BuildContext, State, Provider, Stream...)
- 📝 Break down a quiz question or concept
- 💻 Provide real-world code examples
- 🛠️ Help debug Flutter errors

*Tip: You can tap the 🔑 key icon in the top bar to set up a free Gemini API Key for unrestricted live AI conversation!*''';
      }
    }

    // 2. Nhận diện lời cảm ơn / phản hồi ngắn
    final isThanks = cleanMsg == 'cảm ơn' ||
        cleanMsg == 'cam on' ||
        cleanMsg == 'thanks' ||
        cleanMsg == 'thank you' ||
        cleanMsg == 'tks' ||
        cleanMsg == 'ok' ||
        cleanMsg == 'oke' ||
        cleanMsg == 'cảm ơn bạn';

    if (isThanks) {
      return isVi
          ? 'Không có gì! Rất vui được đồng hành cùng bạn học Flutter. Cứ thoải mái đặt thêm câu hỏi bất kỳ lúc nào nhé! 🚀'
          : "You're very welcome! Always glad to help you master Flutter. Feel free to ask whenever you need! 🚀";
    }

    // 3. Nếu đang trong ngữ cảnh câu hỏi quiz cụ thể (được gọi từ askAboutQuestion)
    if (activeQuestion != null) {
      return formatQuestionAnswer(
        question: activeQuestion,
        userChoiceIndex: userChoiceIndex,
        langCode: langCode,
      );
    }

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/questions.json');
      final List<dynamic> data = jsonDecode(jsonString);
      final bestMatch = _findBestMatch(data, userMessage, langCode);

      if (bestMatch != null) {
        return _formatMatchAnswer(bestMatch, isVi);
      }
    } catch (_) {
      // Bỏ qua lỗi parse JSON
    }

    // Câu trả lời hướng dẫn tự nhiên khi không tìm thấy câu hỏi khớp
    if (isVi) {
      return '''Chào bạn! Hiện tại mình đang chạy ở chế độ **Gia sư Offline** dựa trên ngân hàng câu hỏi Flutter có sẵn.

Để trò chuyện tự do, hỏi đáp liên tục và xin ví dụ code thực tế cùng Gemini AI:
👉 Bạn chỉ cần bấm vào biểu tượng **🔑** ở góc trên và dán **Gemini API Key** miễn phí (lấy tại `aistudio.google.com` trong 30 giây).

Bạn cũng có thể mở phần **Luyện tập** hoặc **Sổ tay câu sai** và bấm hỏi trực tiếp về bất kỳ câu hỏi nào nhé!''';
    } else {
      return '''Hello! I am currently running in **Offline Tutor Mode** using the built-in Flutter quiz data.

To chat freely, ask continuous follow-up questions, and generate real-world code snippets with live Gemini AI:
👉 Tap the **key icon 🔑** in the top bar and paste your free **Gemini API Key** (from `aistudio.google.com` in 30 seconds).

You can also ask directly about any quiz item from **Practice Mode** or **Mistake Handbook**!''';
    }
  }

  QuestionModel? _findBestMatch(
    List<dynamic> data,
    String userMessage,
    String langCode,
  ) {
    final keywords = userMessage
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((k) => k.length >= 3)
        .toList();

    if (keywords.isEmpty) return null;

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
          if (allText.contains(kw)) {
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

    // Chỉ coi là khớp nếu trùng từ 2 từ khóa đặc trưng trở lên
    return bestScore >= 2 ? best : null;
  }

  String _formatMatchAnswer(QuestionModel q, bool isVi) {
    final correctOpt = q.getOptions(isVi ? 'vi' : 'en')[q.correctIndex];
    final explanation = q.explanation.getText(isVi ? 'vi' : 'en');
    final blockTitle = q.blockName.getText(isVi ? 'vi' : 'en');

    if (isVi) {
      return '''Về chủ đề **$blockTitle**, đáp án chuẩn xác là **`$correctOpt`**.

$explanation''';
    } else {
      return '''Regarding **$blockTitle**, the correct answer is **`$correctOpt`**.

$explanation''';
    }
  }
}
