import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../providers/ai_tutor_provider.dart';
import '../providers/language_provider.dart';

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
      builder: (_) => AiTutorSheet(
        question: question,
        userChoiceIndex: userChoiceIndex,
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
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Gradient Header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.aiGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
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
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Demo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _AiChip(
                    label: lang.translate(
                        vi: '🎓 Phân tích chi tiết', en: '🎓 Full Analysis'),
                    isSelected: _selectedAction == 'explain',
                    onTap: () => _switchAction('explain'),
                  ),
                  const SizedBox(width: 8),
                  if (widget.userChoiceIndex != null &&
                      widget.userChoiceIndex != widget.question.correctIndex) ...[
                    _AiChip(
                      label: lang.translate(
                          vi: '💡 Vì sao tôi chọn sai?', en: '💡 Why was I wrong?'),
                      isSelected: _selectedAction == 'why_wrong',
                      onTap: () => _switchAction('why_wrong'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _AiChip(
                    label: lang.translate(
                        vi: '💻 Ví dụ code', en: '💻 Code snippet'),
                    isSelected: _selectedAction == 'code_example',
                    onTap: () => _switchAction('code_example'),
                  ),
                  const SizedBox(width: 8),
                  _AiChip(
                    label: lang.translate(
                        vi: '⚡ Mẹo thi nhớ nhanh', en: '⚡ Exam tip'),
                    isSelected: _selectedAction == 'memory_tip',
                    onTap: () => _switchAction('memory_tip'),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 16),

          // Response Content
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
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    if (ai.state == AiTutorState.error) {
      return Padding(
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: SelectableText(
            ai.response,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
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
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
