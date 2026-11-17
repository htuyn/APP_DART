import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../providers/gamification_provider.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/spaced_repetition_provider.dart';
import '../widgets/ai_tutor_sheet.dart';
import '../widgets/explanation_card.dart';
import '../widgets/language_button.dart';
import '../widgets/option_tile.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';

class PracticeScreen extends StatefulWidget {
  final int initialBlockId;
  final List<QuestionModel>? fixedQuestions;
  final bool isDailyChallenge;

  const PracticeScreen({
    super.key,
    this.initialBlockId = 0,
    this.fixedQuestions,
    this.isDailyChallenge = false,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late int _selectedBlockId;
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _finished = false;
  int _challengeBonus = 0;
  final Map<String, int> _selectedAnswers = {};
  final Map<String, String> _questionLangOverride = {};

  @override
  void initState() {
    super.initState();
    _selectedBlockId = widget.initialBlockId;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();
    final questions =
        widget.fixedQuestions ?? quiz.getQuestionsByBlock(_selectedBlockId);
    final scheme = Theme.of(context).colorScheme;
    final groups = quiz.groupedByBlock;
    final blockIds = groups.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isDailyChallenge
              ? lang.t('daily_challenge_title')
              : lang.t('practice_mode'),
        ),
        actions: [
          if (!widget.isDailyChallenge)
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value:
                    blockIds.contains(_selectedBlockId) || _selectedBlockId == 0
                    ? _selectedBlockId
                    : 0,
                isExpanded: false,
                borderRadius: BorderRadius.circular(16),
                items: [
                  DropdownMenuItem(
                    value: 0,
                    child: Text(
                      lang.t('all_blocks'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  for (final id in blockIds)
                    DropdownMenuItem(
                      value: id,
                      child: SizedBox(
                        width: 150,
                        child: Text(
                          groups[id]!.first.blockName.getText(lang.code).isEmpty
                              ? '${lang.t('block')} $id'
                              : groups[id]!.first.blockName.getText(lang.code),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedBlockId = value;
                    _currentIndex = 0;
                    _selectedAnswers.clear();
                  });
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(0);
                  }
                },
              ),
            ),
          const LanguageButton(),
        ],
      ),
      body: ResponsiveBody(
        child: questions.isEmpty
            ? EmptyView(
                title: lang.t('no_questions'),
                message: lang.t('no_questions_hint'),
                actionText: lang.t('go_home'),
                onAction: () => Navigator.pop(context),
              )
            : _finished
            ? _DailyChallengeSummary(
                correct: _selectedAnswers.entries
                    .where(
                      (entry) => questions.any(
                        (question) =>
                            question.id == entry.key &&
                            question.correctIndex == entry.value,
                      ),
                    )
                    .length,
                total: questions.length,
                bonusXp: _challengeBonus,
                onDone: () => Navigator.pop(context),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Column(
                      children: [
                        // Animated progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            tween: Tween(
                              begin: 0,
                              end: (_currentIndex + 1) / questions.length,
                            ),
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  backgroundColor:
                                      scheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    scheme.primary,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${lang.t('question')} ${_currentIndex + 1}/${questions.length}',
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Difficulty level chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              child: Text(
                                questions[_currentIndex].level,
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.75,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: questions.length,
                      onPageChanged: (index) =>
                          setState(() => _currentIndex = index),
                      itemBuilder: (context, index) {
                        return _QuestionPage(
                          question: questions[index],
                          lang: lang,
                          selected: _selectedAnswers[questions[index].id],
                          langCode:
                              _questionLangOverride[questions[index].id] ??
                              lang.code,
                          onToggleLang: () {
                            final current =
                                _questionLangOverride[questions[index].id] ??
                                lang.code;
                            setState(() {
                              _questionLangOverride[questions[index].id] =
                                  current == 'vi' ? 'en' : 'vi';
                            });
                          },
                          onSelect: (option, isCorrect) async {
                            setState(() {
                              _selectedAnswers[questions[index].id] = option;
                            });
                            await quiz.recordAnswer(
                              question: questions[index],
                              isCorrect: isCorrect,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // ── Bottom nav with separator border ─────────────────────
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
                                    ? () {
                                        _pageController.previousPage(
                                          duration: const Duration(
                                            milliseconds: 280,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        );
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 18,
                                ),
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
                                onPressed:
                                    _currentIndex == questions.length - 1 &&
                                        widget.isDailyChallenge
                                    ? (_selectedAnswers.containsKey(
                                            questions[_currentIndex].id,
                                          )
                                          ? () async {
                                              final awarded = await context
                                                  .read<GamificationProvider>()
                                                  .completeDailyChallenge();
                                              if (!mounted) return;
                                              setState(() {
                                                _challengeBonus = awarded
                                                    ? 50
                                                    : 0;
                                                _finished = true;
                                              });
                                            }
                                          : null)
                                    : _currentIndex < questions.length - 1 &&
                                          (!widget.isDailyChallenge ||
                                              _selectedAnswers.containsKey(
                                                questions[_currentIndex].id,
                                              ))
                                    ? () {
                                        _pageController.nextPage(
                                          duration: const Duration(
                                            milliseconds: 280,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        );
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  widget.isDailyChallenge &&
                                          _currentIndex == questions.length - 1
                                      ? lang.t('daily_challenge_finish')
                                      : lang.t('next'),
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
    );
  }
}

class _QuestionPage extends StatelessWidget {
  final QuestionModel question;
  final LanguageProvider lang;
  final int? selected;
  final String langCode;
  final VoidCallback onToggleLang;
  final Future<void> Function(int option, bool isCorrect) onSelect;

  const _QuestionPage({
    required this.question,
    required this.lang,
    required this.selected,
    required this.langCode,
    required this.onToggleLang,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.getOptions(langCode);
    final answered = selected != null;
    final correct = selected == question.correctIndex;
    final theme = Theme.of(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        question.blockName.getText(langCode),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: lang.t('toggle_question_lang'),
                      onPressed: onToggleLang,
                      icon: const Icon(Icons.translate_rounded, size: 20),
                    ),
                    Consumer<SpacedRepetitionProvider>(
                      builder: (context, sr, _) {
                        final isBookmarked = sr.isBookmarked(question.id);
                        return IconButton(
                          tooltip: isBookmarked ? 'Bỏ lưu ôn tập' : 'Lưu ôn tập AI',
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isBookmarked
                                ? AppColors.accentPurple
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 22,
                          ),
                          onPressed: () {
                            if (isBookmarked) {
                              sr.removeBookmark(question.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã bỏ lưu khỏi danh sách ôn tập AI'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            } else {
                              sr.bookmarkQuestion(question.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã lưu vào danh sách ôn tập AI Spaced Repetition!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  question.question.getText(langCode),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < options.length; index++)
          OptionTile(
            label: optionLabel(index),
            text: options[index],
            state: !answered
                ? OptionState.idle
                : index == question.correctIndex
                ? OptionState.correct
                : index == selected
                ? OptionState.wrong
                : OptionState.idle,
            onTap: answered
                ? null
                : () async => onSelect(index, index == question.correctIndex),
          ),
        if (answered) ...[
          const SizedBox(height: 12),
          ExplanationCard(
            correct: correct,
            title: correct ? lang.t('correct_bang') : lang.t('explanation'),
            body: question.explanation.getText(langCode),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              AiTutorSheet.show(
                context,
                question: question,
                userChoiceIndex: selected,
              );
            },
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(lang.t('ask_ai')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentPurple,
              side: BorderSide(
                color: AppColors.accentPurple.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DailyChallengeSummary extends StatelessWidget {
  const _DailyChallengeSummary({
    required this.correct,
    required this.total,
    required this.bonusXp,
    required this.onDone,
  });

  final int correct;
  final int total;
  final int bonusXp;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              lang.t('daily_challenge_result'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('$correct/$total ${lang.t('daily_challenge_correct')}'),
            const SizedBox(height: 8),
            Text('${lang.t('daily_challenge_xp_earned')}: +$bonusXp XP'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
              child: Text(lang.t('close')),
            ),
          ],
        ),
      ),
    );
  }
}
