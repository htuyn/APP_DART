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

class _ExamResultScreenState extends State<ExamResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuizProvider>().reloadProgress();
      context.read<StatsProvider>().loadHistory();
    });
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: passed ? AppColors.successGradient : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
                boxShadow: [
                  BoxShadow(
                    color: (passed ? AppColors.success : AppColors.primary)
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      passed ? Icons.emoji_events_rounded : Icons.school_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    passed ? lang.t('passed') : lang.t('keep_trying'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${tenPoint.toStringAsFixed(1)} / 10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${result.score}/${result.totalQuestions} ${lang.t('questions')} · ${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                          height: 28,
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                        _Stat(
                          label: lang.t('incorrect'),
                          value: '${result.totalQuestions - result.score}',
                          icon: Icons.cancel_outlined,
                        ),
                        Container(
                          width: 1,
                          height: 28,
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
            const SizedBox(height: 20),
            if (result.wrongQuestionIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      openAppPage(const WrongQuestionsScreen()),
                    );
                  },
                  icon: const Icon(Icons.bookmark_remove_rounded),
                  label: Text(lang.t('review_wrong')),
                ),
              ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  openAppPage(ExamScreen(paperIndex: exam.paperIndex)),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(lang.t('retake')),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home_rounded),
              label: Text(lang.t('go_home')),
            ),
            if (questions.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                lang.t('see_answers'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                    explanation: questions[i].explanation.getText(lang.code),
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
