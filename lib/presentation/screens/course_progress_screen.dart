import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/course_progress_provider.dart';
import '../providers/language_provider.dart';
import 'exam_screen.dart';

class CourseProgressScreen extends StatelessWidget {
  const CourseProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<CourseProgressProvider>();
    final language = context.watch<LanguageProvider>();
    final eligibility = progress.certificateEligibility;

    return Scaffold(
      appBar: AppBar(
        title: Text(language.t('course_progress_title')),
        actions: [
          IconButton(
            tooltip: language.t('refresh'),
            onPressed: progress.isLoading ? null : progress.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProgressMetric(
            label: language.t('completed_blocks_progress'),
            value: '${progress.completedBlockCount}/${progress.totalBlockCount}',
            fraction: progress.totalBlockCount == 0
                ? 0
                : progress.completedBlockCount / progress.totalBlockCount,
          ),
          _ProgressMetric(
            label: language.t('practice_questions_progress'),
            value:
                '${progress.practiceQuestionsAnswered}/${progress.requiredPracticeQuestions}',
            fraction: (progress.practiceQuestionsAnswered /
                    progress.requiredPracticeQuestions)
                .clamp(0, 1),
          ),
          _ProgressMetric(
            label: language.t('accuracy_progress'),
            value: '${progress.overallAccuracyPercent.toStringAsFixed(1)}%',
            fraction: (progress.overallAccuracyPercent / 80).clamp(0, 1),
          ),
          _ProgressMetric(
            label: language.t('capstone_progress'),
            value: progress.capstoneExamScore == null ||
                    progress.capstoneExamTotal == null
                ? language.t('capstone_not_taken')
                : '${progress.capstoneExamScore}/${progress.capstoneExamTotal}',
            fraction: progress.capstoneExamScore == null ||
                    progress.capstoneExamTotal == null ||
                    progress.capstoneExamTotal == 0
                ? 0
                : (progress.capstoneExamScore! /
                        progress.capstoneExamTotal! /
                        0.8)
                    .clamp(0, 1),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                eligibility.eligible
                    ? Icons.workspace_premium
                    : Icons.lock_outline,
              ),
              title: Text(language.t('course_requirements')),
              subtitle: Text(
                eligibility.eligible
                    ? (language.code == 'vi'
                        ? 'Bạn đã đáp ứng mọi tiêu chí chứng chỉ.'
                        : 'You have met all certificate criteria.')
                    : language
                        .t('course_requirements_body')
                        .replaceAll(
                          '{required}',
                          '${progress.requiredPracticeQuestions}',
                        ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: progress.questions.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const ExamScreen(isCapstoneExam: true),
                      ),
                    ),
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: Text(language.t('start_capstone')),
          ),
          if (progress.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              progress.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.value,
    required this.fraction,
  });

  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label)),
                  const SizedBox(width: 12),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: fraction),
            ],
          ),
        ),
      );
}
