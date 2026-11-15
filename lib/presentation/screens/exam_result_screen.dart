import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/quiz_result_model.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import 'exam_screen.dart';
import 'wrong_questions_screen.dart';

class ExamResultScreen extends StatelessWidget {
  final QuizResultModel result;

  const ExamResultScreen({super.key, required this.result});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();
    final percentage = result.percentage;
    final isPassed = percentage >= 60.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate(vi: 'Kết Quả Thi Thử', en: 'Exam Results')),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Score circle card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                      size: 64,
                      color: isPassed ? Colors.amber.shade700 : Colors.orange.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPassed
                          ? lang.translate(vi: 'Chúc Mừng! Bạn Đã Đạt', en: 'Congratulations! You Passed')
                          : lang.translate(vi: 'Cần Cố Gắng Hơn!', en: 'Keep Practicing!'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${result.score}/${result.totalQuestions}',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ResultStat(
                          icon: Icons.timer_outlined,
                          label: lang.translate(vi: 'Thời gian', en: 'Time Spent'),
                          value: _formatTime(result.timeSpentSeconds),
                        ),
                        _ResultStat(
                          icon: Icons.check_circle_outline,
                          label: lang.translate(vi: 'Câu đúng', en: 'Correct'),
                          value: '${result.score}',
                          color: Colors.green.shade700,
                        ),
                        _ResultStat(
                          icon: Icons.cancel_outlined,
                          label: lang.translate(vi: 'Câu sai', en: 'Incorrect'),
                          value: '${result.wrongQuestionIds.length}',
                          color: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons (minHeight 48dp)
            if (result.wrongQuestionIds.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.bookmark_remove_rounded),
                  label: Text(
                    lang.translate(
                      vi: 'Làm lại ${result.wrongQuestionIds.length} câu sai vừa rồi',
                      en: 'Review ${result.wrongQuestionIds.length} incorrect questions',
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WrongQuestionsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(lang.translate(vi: 'Thi lại lần nữa', en: 'Retake Exam')),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ExamScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: Text(lang.translate(vi: 'Về trang chủ', en: 'Back to Home')),
                onPressed: () {
                  quiz.initialize(); // Refresh state
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _ResultStat({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color ?? Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
