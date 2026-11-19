import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/navigation/app_page_route.dart';
import '../../data/models/quiz_result_model.dart';
import '../providers/exam_provider.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/option_tile.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';
import 'exam_result_screen.dart';

class ExamScreen extends StatefulWidget {
  final int? paperIndex;
  final bool isCapstoneExam;

  const ExamScreen({
    super.key,
    this.paperIndex,
    this.isCapstoneExam = false,
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late final PageController _pageController;
  late final ExamProvider _exam;
  int _currentIndex = 0;
  bool _started = false;
  bool _openedResult = false;
  bool _showQuestionGrid = true;

  ThemeData get theme => Theme.of(context);

  String optionLabel(int index) {
    const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '${index + 1}';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _exam = context.read<ExamProvider>();
    _exam.addListener(_onExam);
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  void _begin() {
    if (!mounted || _started) return;
    final quiz = context.read<QuizProvider>();
    if (quiz.allQuestions.isEmpty) return;
    _started = true;
    _exam.startExam(
      allQuestions: quiz.allQuestions,
      numberOfQuestions: ExamProvider.paperSize,
      durationMinutes: ExamProvider.paperMinutes,
      paperIndex: widget.paperIndex,
      isCapstoneExam: widget.isCapstoneExam,
    );
  }

  void _onExam() {
    final result = _exam.lastResult;
    if (!_exam.isSubmitted || result == null) return;
    _openResult(result);
  }

  void _openResult(QuizResultModel result) {
    if (_openedResult || !mounted) return;
    _openedResult = true;
    Navigator.of(context).pushReplacement(
      openAppPage(ExamResultScreen(result: result)),
    );
  }

  @override
  void dispose() {
    _exam.removeListener(_onExam);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmSubmit() async {
    final lang = context.read<LanguageProvider>();
    final unanswered = _exam.examQuestions.length - _exam.userAnswers.length;
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('submit_title')),
        content: Text(
          unanswered > 0
              ? lang.translate(
            vi: 'Bạn còn $unanswered câu chưa trả lời. Bạn có chắc muốn nộp bài không?',
            en: 'You have $unanswered unanswered questions. Are you sure you want to submit?',
          )
              : lang.translate(
            vi: 'Bạn đã hoàn thành tất cả câu hỏi. Nộp bài ngay để xem kết quả?',
            en: 'You have completed all questions. Submit now to view results?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.t('continue_exam')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.t('submit')),
          ),
        ],
      ),
    );
    if (shouldSubmit == true && mounted) {
      await _exam.submitExam();
    }
  }

  Future<void> _confirmLeave() async {
    final lang = context.read<LanguageProvider>();
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('leave_title')),
        content: Text(lang.t('leave_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.t('stay')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.t('leave')),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) {
      _exam.abandonExam();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final exam = context.watch<ExamProvider>();
    final quiz = context.watch<QuizProvider>();
    final questions = exam.examQuestions;
    final scheme = Theme.of(context).colorScheme;
    final title = widget.paperIndex == null
        ? lang.t('random_exam')
        : '${lang.t('paper')} ${widget.paperIndex!.toString().padLeft(2, '0')}';

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.t('mock_exam'))),
        body: quiz.state == QuizLoadingState.error
            ? ErrorView(
          message: quiz.errorMessage ?? lang.t('load_error'),
          retryText: lang.t('retry'),
          onRetry: quiz.initialize,
        )
            : LoadingView(message: lang.t('loading_questions')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmLeave,
            tooltip: lang.t('leave_title'),
          ),
          actions: [
            // Grid toggle with animated icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                key: ValueKey(_showQuestionGrid),
                tooltip: lang.t('question_status'),
                icon: Icon(
                  _showQuestionGrid
                      ? Icons.grid_on_rounded
                      : Icons.grid_off_rounded,
                ),
                onPressed: () =>
                    setState(() => _showQuestionGrid = !_showQuestionGrid),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: FilledButton.icon(
                onPressed: _handleConfirmSubmit,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(lang.t('submit')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ResponsiveBody(
          child: Column(
            children: [
              // ── Status bar: timer + progress chip ─────────────────────────
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      CountdownTimerWidget(
                        remainingSeconds: exam.remainingSeconds,
                        totalSeconds: exam.totalDurationSeconds,
                        prominent: true,
                      ),
                      const Spacer(),
                      // Answered progress pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: exam.answeredCount == questions.length
                              ? AppColors.success.withValues(alpha: 0.14)
                              : scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              exam.answeredCount == questions.length
                                  ? Icons.check_circle_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 15,
                              color: exam.answeredCount == questions.length
                                  ? AppColors.success
                                  : scheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${exam.answeredCount}/${questions.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: exam.answeredCount == questions.length
                                    ? AppColors.success
                                    : scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Question grid panel ───────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: _showQuestionGrid
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LegendDot(
                                    color: scheme.primary,
                                    label: lang.t('answered')),
                                const SizedBox(width: 16),
                                _LegendDot(
                                    color: scheme.outlineVariant,
                                    label: lang.t('unanswered')),
                                const SizedBox(width: 16),
                                _LegendDot(
                                    color: AppColors.warning,
                                    label: lang.t('flagged')),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 2, 16, 10),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: questions.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.sizeOf(context).width >= 840
                                        ? 15
                                        : 10,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                              ),
                              itemBuilder: (context, index) {
                                final current = index == _currentIndex;
                                final answered =
                                    exam.userAnswers.containsKey(index);
                                final flagged =
                                    exam.flagged.contains(index);

                                Color bg;
                                Color fg;
                                if (current) {
                                  bg = scheme.primary;
                                  fg = scheme.onPrimary;
                                } else if (answered) {
                                  bg = scheme.primary
                                      .withValues(alpha: 0.18);
                                  fg = scheme.primary;
                                } else {
                                  bg = scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5);
                                  fg = scheme.onSurface;
                                }

                                return Material(
                                  color: bg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: flagged
                                          ? AppColors.warning
                                          : current
                                              ? scheme.primary
                                              : scheme.outlineVariant,
                                      width:
                                          flagged || current ? 2.0 : 1.0,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    onTap: () =>
                                        _pageController.jumpToPage(index),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: fg,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Question PageView ─────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: questions.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    final selected = exam.userAnswers[index];
                    final options = question.getOptions(lang.code);
                    final flagged = exam.flagged.contains(index);

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        // Question header row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${lang.t('question')} ${index + 1}/${questions.length}',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Animated flag chip
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              child: ActionChip(
                                visualDensity: VisualDensity.compact,
                                avatar: Icon(
                                  flagged
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  size: 17,
                                  color: flagged
                                      ? AppColors.warning
                                      : scheme.outline,
                                ),
                                label: Text(
                                  flagged
                                      ? lang.t('flagged')
                                      : lang.t('flag'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: flagged
                                        ? AppColors.warning
                                        : scheme.onSurface,
                                  ),
                                ),
                                backgroundColor: flagged
                                    ? AppColors.warning
                                        .withValues(alpha: 0.1)
                                    : null,
                                side: BorderSide(
                                  color: flagged
                                      ? AppColors.warning
                                          .withValues(alpha: 0.4)
                                      : scheme.outlineVariant,
                                ),
                                onPressed: () =>
                                    exam.toggleFlag(index),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: quiz.isBookmarked(question.id)
                                  ? lang.t('bookmarked')
                                  : lang.t('bookmark'),
                              onPressed: () => quiz.toggleBookmark(question.id),
                              icon: Icon(
                                quiz.isBookmarked(question.id)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 20,
                                color: quiz.isBookmarked(question.id)
                                    ? AppColors.warning
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Question card — elevated with subtle shadow
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppMetrics.radiusCard),
                            side: BorderSide(
                              color: scheme.outlineVariant
                                  .withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(18, 16, 18, 18),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Block tag
                                if (question.blockName
                                    .getText(lang.code)
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8),
                                    child: Text(
                                      question.blockName
                                          .getText(lang.code),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                Text(
                                  question.question.getText(lang.code),
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontSize: 16.5,
                                    height: 1.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Answer options
                        for (var opt = 0;
                            opt < options.length;
                            opt++)
                          OptionTile(
                            label: optionLabel(opt),
                            text: options[opt],
                            state: selected == opt
                                ? OptionState.selected
                                : OptionState.idle,
                            onTap: () =>
                                exam.selectAnswer(index, opt),
                          ),
                      ],
                    );
                  },
                ),
              ),

              // ── Bottom Navigation Bar ─────────────────────────────────────
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _currentIndex > 0
                                ? () => _pageController.previousPage(
                                      duration: const Duration(
                                          milliseconds: 280),
                                      curve: Curves.easeOutCubic,
                                    )
                                : null,
                            icon: const Icon(Icons.arrow_back_rounded,
                                size: 18),
                            label: Text(lang.t('previous')),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _currentIndex < questions.length - 1
                                ? () => _pageController.nextPage(
                                      duration: const Duration(
                                          milliseconds: 280),
                                      curve: Curves.easeOutCubic,
                                    )
                                : _handleConfirmSubmit,
                            icon: Icon(
                              _currentIndex < questions.length - 1
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_circle_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _currentIndex < questions.length - 1
                                  ? lang.t('next')
                                  : lang.t('submit'),
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor:
                                  _currentIndex < questions.length - 1
                                      ? null
                                      : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}