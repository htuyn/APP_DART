import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exam_provider.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/option_tile.dart';
import '../widgets/state_views.dart';
import 'exam_result_screen.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Start exam on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quiz = context.read<QuizProvider>();
      final exam = context.read<ExamProvider>();
      exam.startExam(
        allQuestions: quiz.allQuestions,
        numberOfQuestions: 20,
        durationMinutes: 15,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmSubmit() async {
    final lang = context.read<LanguageProvider>();
    final exam = context.read<ExamProvider>();

    final unansweredCount =
        exam.examQuestions.length - exam.userAnswers.length;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.translate(vi: 'Nộp bài thi?', en: 'Submit Exam?')),
        content: Text(
          unansweredCount > 0
              ? lang.translate(
                  vi: 'Bạn còn $unansweredCount câu chưa trả lời. Bạn có chắc muốn nộp không?',
                  en: 'You have $unansweredCount unanswered questions. Are you sure you want to submit?',
                )
              : lang.translate(
                  vi: 'Bạn đã hoàn thành tất cả câu hỏi. Nộp bài để xem điểm số nhé!',
                  en: 'You have answered all questions. Submit to view your score!',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.translate(vi: 'Làm tiếp', en: 'Continue')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.translate(vi: 'Nộp bài', en: 'Submit')),
          ),
        ],
      ),
    );

    if (shouldSubmit == true && mounted) {
      final result = await exam.submitExam();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ExamResultScreen(result: result),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final exam = context.watch<ExamProvider>();
    final questions = exam.examQuestions;

    // Listen for automatic timer submission
    if (exam.isSubmitted && exam.lastResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ExamResultScreen(result: exam.lastResult!),
            ),
          );
        }
      });
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.translate(vi: 'Thi Thử', en: 'Mock Exam'))),
        body: const LoadingView(),
      );
    }

    final labels = ['A', 'B', 'C', 'D'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang.translate(vi: 'Rời phòng thi?', en: 'Leave Exam?')),
            content: Text(lang.translate(
              vi: 'Bài thi đang tính giờ. Nếu rời khỏi, kết quả của bạn sẽ không được ghi nhận.',
              en: 'Exam is in progress. If you leave, your progress will be lost.',
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(lang.translate(vi: 'Ở lại', en: 'Stay')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  lang.translate(vi: 'Rời đi', en: 'Leave'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.translate(vi: 'Thi Thử', en: 'Mock Exam')),
          actions: [
            Center(
              child: CountdownTimerWidget(
                remainingSeconds: exam.remainingSeconds,
                totalSeconds: exam.totalDurationSeconds,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _handleConfirmSubmit,
              child: Text(
                lang.translate(vi: 'NỘP BÀI', en: 'SUBMIT'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Top question counter and navigation bubbles
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: questions.length,
                itemBuilder: (context, idx) {
                  final isAnswered = exam.userAnswers.containsKey(idx);
                  final isCurrent = idx == _currentIndex;

                  return GestureDetector(
                    onTap: () {
                      _pageController.jumpToPage(idx);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : isAnswered
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                        border: Border.all(
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCurrent
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: questions.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final ans = exam.userAnswers[index];
                  final qOptions = q.getOptions(lang.code);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${lang.translate(vi: "Câu", en: "Question")} ${index + 1}/${questions.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              q.blockName.getText(lang.code),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q.question.getText(lang.code),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(qOptions.length, (optIdx) {
                          return OptionTile(
                            label: labels[optIdx],
                            text: qOptions[optIdx],
                            state: ans == optIdx ? OptionState.selected : OptionState.idle,
                            onTap: () {
                              exam.selectAnswer(index, optIdx);
                            },
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _currentIndex > 0
                            ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        child: Text(lang.translate(vi: 'Câu trước', en: 'Previous')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentIndex < questions.length - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : _handleConfirmSubmit,
                        child: Text(
                          _currentIndex < questions.length - 1
                              ? lang.translate(vi: 'Câu tiếp', en: 'Next')
                              : lang.translate(vi: 'Nộp bài', en: 'Submit'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
