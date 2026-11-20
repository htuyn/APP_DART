import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/language_button.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';

class FlashcardScreen extends StatefulWidget {
  final int? blockId;
  final List<QuestionModel>? fixedQuestions;

  const FlashcardScreen({
    super.key,
    this.blockId,
    this.fixedQuestions,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late List<QuestionModel> _questions;
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _nextCard() {
    if (_currentIndex < _questions.length - 1) {
      _resetFlip();
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      _resetFlip();
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _resetFlip() {
    if (_isFlipped) {
      _flipController.reset();
      _isFlipped = false;
    }
  }

  void _shuffleCards() {
    setState(() {
      _questions.shuffle();
      _currentIndex = 0;
      _resetFlip();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<LanguageProvider>().translate(
                vi: 'Đã xáo trộn danh sách thẻ!',
                en: 'Cards shuffled successfully!',
              ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (widget.fixedQuestions != null) {
      _questions = widget.fixedQuestions!;
    } else if (widget.blockId != null) {
      _questions = quiz.getQuestionsByBlock(widget.blockId!);
    } else {
      _questions = quiz.allQuestions;
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.t('choose_block'))),
        body: EmptyView(
          icon: Icons.style_outlined,
          title: lang.translate(vi: 'Không có thẻ học', en: 'No flashcards'),
          message: lang.translate(
            vi: 'Chưa có câu hỏi nào cho khối kiến thức này.',
            en: 'No questions available for this block.',
          ),
          actionText: lang.t('go_home'),
          onAction: () => Navigator.of(context).pop(),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final total = _questions.length;
    final progress = (_currentIndex + 1) / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate(
            vi: 'Thẻ Ghi Nhớ Flashcard',
            en: 'Flashcard Study',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: lang.translate(vi: 'Xáo trộn thẻ', en: 'Shuffle cards'),
            onPressed: _shuffleCards,
          ),
          const LanguageButton(),
        ],
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            // Progress Bar & Counter
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lang.translate(vi: "Thẻ", en: "Card")} ${_currentIndex + 1} / $total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${lang.t('block')} ${currentQuestion.blockId}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Card Container with Flip Animation
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  onTap: _toggleFlip,
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! < -200) {
                        _nextCard();
                      } else if (details.primaryVelocity! > 200) {
                        _previousCard();
                      }
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * math.pi;
                      final isBackView = angle >= math.pi / 2;

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: isBackView
                            ? Transform(
                                transform: Matrix4.identity()..rotateY(math.pi),
                                alignment: Alignment.center,
                                child: _buildCardBack(
                                  context: context,
                                  question: currentQuestion,
                                  lang: lang,
                                  scheme: scheme,
                                  isDark: isDark,
                                ),
                              )
                            : _buildCardFront(
                                context: context,
                                question: currentQuestion,
                                lang: lang,
                                scheme: scheme,
                                isDark: isDark,
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  // Previous Card Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: Text(
                        lang.translate(vi: 'Thẻ trước', en: 'Previous'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Flip Button
                  FilledButton.icon(
                    onPressed: _toggleFlip,
                    icon: const Icon(Icons.flip_rounded, size: 20),
                    label: Text(
                      _isFlipped
                          ? lang.translate(vi: 'Mặt trước', en: 'Front')
                          : lang.translate(vi: 'Lật thẻ', en: 'Flip'),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Next Card Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _currentIndex < total - 1 ? _nextCard : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: Text(
                        lang.translate(vi: 'Thẻ tiếp', en: 'Next'),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Front Side of Card
  Widget _buildCardFront({
    required BuildContext context,
    required QuestionModel question,
    required LanguageProvider lang,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final titleText = question.blockName.getText(lang.code);
    final options = question.getOptions(lang.code);

    return Card(
      elevation: 6,
      shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.3 : 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.widgets_rounded,
                            size: 14, color: scheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            titleText.isEmpty
                                ? '${lang.t('block')} ${question.blockId}'
                                : titleText,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    question.getLevelText(lang.code),
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question Section
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.translate(
                        vi: 'CÂU HỎI',
                        en: 'QUESTION',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.question.getText(lang.code),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                            color: scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      lang.translate(
                        vi: 'CÁC LỰA CHỌN:',
                        en: 'OPTIONS:',
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (int i = 0; i < options.length; i++) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: scheme.primary.withValues(alpha: 0.12),
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[i],
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tap to Flip Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    lang.translate(
                      vi: 'Chạm vào thẻ để xem đáp án',
                      en: 'Tap card to flip for answer',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Back Side of Card
  Widget _buildCardBack({
    required BuildContext context,
    required QuestionModel question,
    required LanguageProvider lang,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final options = question.getOptions(lang.code);
    final correctIdx = question.correctIndex;
    final correctAnswerText = (correctIdx >= 0 && correctIdx < options.length)
        ? options[correctIdx]
        : '';
    final explanation = question.explanation.getText(lang.code);

    return Card(
      elevation: 6,
      shadowColor: scheme.shadow.withValues(alpha: isDark ? 0.3 : 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.success.withValues(alpha: 0.5),
          width: 2.0,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Correct Answer Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        lang.translate(
                          vi: 'ĐÁP ÁN ĐÚNG',
                          en: 'CORRECT ANSWER',
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    question.getLevelText(lang.code),
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Correct Answer Display Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.12),
                    AppColors.success.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.success,
                    child: Text(
                      String.fromCharCode(65 + correctIdx),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      correctAnswerText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detailed Explanation Section
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_rounded,
                            size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(
                          lang.t('explanation'),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Text(
                        explanation.isEmpty
                            ? lang.translate(
                                vi: 'Không có giải thích bổ sung cho câu này.',
                                en: 'No detailed explanation available.',
                              )
                            : explanation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: scheme.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tap to Flip Back Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: 18, color: scheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    lang.translate(
                      vi: 'Chạm để lật lại mặt trước',
                      en: 'Tap to flip back to question',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
