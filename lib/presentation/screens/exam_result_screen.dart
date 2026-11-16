import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_page_route.dart';
import '../../data/models/quiz_result_model.dart';
import '../providers/exam_provider.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/explanation_card.dart';
import '../widgets/language_button.dart';
import '../widgets/responsive_body.dart';
import 'exam_screen.dart';
import 'wrong_questions_screen.dart';

class ExamResultScreen extends StatefulWidget {
  final QuizResultModel result;

  const ExamResultScreen({super.key, required this.result});

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _heroController;
  late Animation<double> _heroScale;
  late Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heroScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutBack),
    );
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _heroController.forward();
      context.read<QuizProvider>().reloadProgress();
      context.read<StatsProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remain.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final exam = context.watch<ExamProvider>();
    final result = widget.result;
    final percentage = result.percentage;
    final passed = percentage >= 60;
    final tenPoint = result.totalQuestions == 0
        ? 0.0
        : result.score / result.totalQuestions * 10;
    final questions = exam.examQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('results_title')),
        automaticallyImplyLeading: false,
        actions: const [LanguageButton()],
      ),
      body: ResponsiveBody(
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // ── Hero Score Card (animated) ──────────────────────────────────
            FadeTransition(
              opacity: _heroFade,
              child: ScaleTransition(
                scale: _heroScale,
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        passed ? AppColors.successGradient : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
                    boxShadow: [
                      BoxShadow(
                        color: (passed ? AppColors.success : AppColors.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                  child: Column(
                    children: [
                      // Trophy / School icon
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          passed ? Icons.emoji_events_rounded : Icons.school_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        passed ? lang.t('passed') : lang.t('keep_trying'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Big score
                      Text(
                        '${tenPoint.toStringAsFixed(1)} / 10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${result.score}/${result.totalQuestions} ${lang.t('questions')} · ${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            _Stat(
                              label: lang.t('correct'),
                              value: '${result.score}',
                              icon: Icons.check_circle_outline_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            _Stat(
                              label: lang.t('incorrect'),
                              value:
                                  '${result.totalQuestions - result.score}',
                              icon: Icons.cancel_outlined,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            _Stat(
                              label: lang.t('time_spent'),
                              value: _formatTime(result.timeSpentSeconds),
                              icon: Icons.timer_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Action Buttons ──────────────────────────────────────────────
            if (result.wrongQuestionIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    openAppPage(const WrongQuestionsScreen()),
                  ),
                  icon: const Icon(Icons.bookmark_remove_rounded, size: 18),
                  label: Text(lang.t('review_wrong')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                openAppPage(ExamScreen(paperIndex: exam.paperIndex)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(lang.t('retake')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: Text(lang.t('go_home')),
            ),

            // ── Answer Review Section ───────────────────────────────────────
            if (questions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  lang.t('see_answers'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              for (var i = 0; i < questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewTile(
                    index: i,
                    selected: exam.userAnswers[i],
                    yourAnswer: lang.t('your_answer'),
                    rightAnswer: lang.t('right_answer'),
                    notAnswered: lang.t('not_answered'),
                    explanationLabel: lang.t('explanation'),
                    question: questions[i].question.getText(lang.code),
                    options: questions[i].getOptions(lang.code),
                    correctIndex: questions[i].correctIndex,
                    explanation:
                        questions[i].explanation.getText(lang.code),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final int index;
  final int? selected;
  final String yourAnswer;
  final String rightAnswer;
  final String notAnswered;
  final String explanationLabel;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const _ReviewTile({
    required this.index,
    required this.selected,
    required this.yourAnswer,
    required this.rightAnswer,
    required this.notAnswered,
    required this.explanationLabel,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final correct = selected == correctIndex;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final picked = selected != null && selected! >= 0 && selected! < options.length
        ? '${optionLabel(selected!)}. ${options[selected!]}'
        : notAnswered;
    final answer = correctIndex >= 0 && correctIndex < options.length
        ? '${optionLabel(correctIndex)}. ${options[correctIndex]}'
        : '';

    return Card(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (correct ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: correct ? AppColors.success : AppColors.error,
              ),
            ),
          ),
          title: Text(
            question,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          subtitle: Text(
            correct ? rightAnswer : '$yourAnswer: $picked',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: correct ? AppColors.success : AppColors.error,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$yourAnswer: $picked',
                      style: TextStyle(
                        color: correct ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$rightAnswer: $answer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ExplanationCard(
              correct: correct,
              title: explanationLabel,
              body: explanation,
            ),
          ],
        ),
      ),
    );
  }
}
