import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../providers/ai_tutor_provider.dart';
import '../providers/language_provider.dart';
import '../screens/ai_chat_screen.dart';
import 'markdown_message.dart';

class AiTutorSheet extends StatefulWidget {
  final QuestionModel question;
  final int? userChoiceIndex;

  const AiTutorSheet({
    super.key,
    required this.question,
    this.userChoiceIndex,
  });

  static Future<void> show(
    BuildContext context, {
    required QuestionModel question,
    int? userChoiceIndex,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Provider scope riêng cho từng lần mở sheet: tránh dữ liệu cũ/race
      // khi người dùng mở câu hỏi khác hoặc bấm chip liên tục.
      builder: (_) => ChangeNotifierProvider(
        create: (_) => AiTutorProvider(),
        child: AiTutorSheet(
          question: question,
          userChoiceIndex: userChoiceIndex,
        ),
      ),
    );
  }

  @override
  State<AiTutorSheet> createState() => _AiTutorSheetState();
}

class _AiTutorSheetState extends State<AiTutorSheet> {
  String _selectedAction = 'explain';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestExplanation();
    });
  }

  void _requestExplanation() {
    final lang = context.read<LanguageProvider>();
    final ai = context.read<AiTutorProvider>();
    ai.askTutor(
      question: widget.question,
      userChoiceIndex: widget.userChoiceIndex,
      langCode: lang.code,
      action: _selectedAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final ai = context.watch<AiTutorProvider>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.aiGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.translate(
                          vi: 'Gia Sư AI Flutter',
                          en: 'AI Flutter Tutor',
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.translate(
                          vi: 'Phân tích chuyên sâu & mẹo ghi nhớ',
                          en: 'In-depth analysis & memory tips',
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'AI Tutor',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _AiChip(
                    label: lang.translate(
                      vi: '🎓 Phân tích chi tiết',
                      en: '🎓 Full Analysis',
                    ),
                    isSelected: _selectedAction == 'explain',
                    onTap: () => _switchAction('explain'),
                  ),
                  const SizedBox(width: 8),
                  if (widget.userChoiceIndex != null &&
                      widget.userChoiceIndex != widget.question.correctIndex) ...[
                    _AiChip(
                      label: lang.translate(
                        vi: '💡 Vì sao tôi chọn sai?',
                        en: '💡 Why was I wrong?',
                      ),
                      isSelected: _selectedAction == 'why_wrong',
                      onTap: () => _switchAction('why_wrong'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _AiChip(
                    label: lang.translate(
                      vi: '💻 Ví dụ code',
                      en: '💻 Code snippet',
                    ),
                    isSelected: _selectedAction == 'code_example',
                    onTap: () => _switchAction('code_example'),
                  ),
                  const SizedBox(width: 8),
                  _AiChip(
                    label: lang.translate(
                      vi: '⚡ Mẹo thi nhớ nhanh',
                      en: '⚡ Exam tip',
                    ),
                    isSelected: _selectedAction == 'memory_tip',
                    onTap: () => _switchAction('memory_tip'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Flexible(
            child: _buildResponseContent(ai, lang),
          ),
        ],
      ),
    );
  }

  void _switchAction(String action) {
    setState(() => _selectedAction = action);
    _requestExplanation();
  }

  Widget _buildResponseContent(AiTutorProvider ai, LanguageProvider lang) {
    if (ai.state == AiTutorState.thinking) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lang.translate(
                vi: 'AI đang phân tích câu hỏi...',
                en: 'AI is analyzing the question...',
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (ai.state == AiTutorState.error) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              ai.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestExplanation,
              child: Text(lang.translate(vi: 'Thử lại', en: 'Retry')),
            ),
          ],
        ),
      );
    }

    if (ai.state == AiTutorState.done) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: MarkdownMessage(
                data: ai.response,
                selectable: true,
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  context,
                  '/ai-chat',
                  arguments: AiChatArgs(
                    question: widget.question,
                    userChoiceIndex: widget.userChoiceIndex,
                  ),
                );
              },
              icon: const Icon(Icons.forum_rounded, size: 18),
              label: Text(
                lang.translate(
                  vi: 'Mở Chat trực tiếp với AI về câu này',
                  en: 'Open Live AI Chat for this question',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentPurple,
                side: BorderSide(
                  color: AppColors.accentPurple.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _AiChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AiChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.aiGradient : null,
          color: isSelected
              ? null
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
