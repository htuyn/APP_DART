import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/ai_tutor_sheet.dart';
import '../widgets/explanation_card.dart';
import '../widgets/language_button.dart';
import '../widgets/option_tile.dart';
import '../widgets/responsive_body.dart';
import '../widgets/state_views.dart';

class PracticeScreen extends StatefulWidget {
  final int initialBlockId;

  const PracticeScreen({super.key, this.initialBlockId = 0});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late int _selectedBlockId;
  late final PageController _pageController;
  int _currentIndex = 0;
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
    final questions = quiz.getQuestionsByBlock(_selectedBlockId);
    final scheme = Theme.of(context).colorScheme;
    final groups = quiz.groupedByBlock;
    final blockIds = groups.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('practice_mode')),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: blockIds.contains(_selectedBlockId) || _selectedBlockId == 0
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
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_currentIndex + 1) / questions.length,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            questions[_currentIndex].level,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: questions.length,
                      onPageChanged: (index) => setState(() => _currentIndex = index),
                      itemBuilder: (context, index) {
                        return _QuestionPage(
                          question: questions[index],
                          lang: lang,
                          selected: _selectedAnswers[questions[index].id],
                          langCode: _questionLangOverride[questions[index].id] ?? lang.code,
                          onToggleLang: () {
                            final current =
                                _questionLangOverride[questions[index].id] ?? lang.code;
                            setState(() {
                              _questionLangOverride[questions[index].id] =
                                  current == 'vi' ? 'en' : 'vi';
                            });
                          },
                          onSelect: (option, isCorrect) {
                            setState(() {
                              _selectedAnswers[questions[index].id] = option;
                            });
                            quiz.recordAnswer(
                              question: questions[index],
                              isCorrect: isCorrect,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _currentIndex > 0
                                  ? () {
                                      _pageController.previousPage(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeOutCubic,
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.arrow_back_rounded, size: 18),
                              label: Text(lang.t('previous')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _currentIndex < questions.length - 1
                                  ? () {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeOutCubic,
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                              label: Text(lang.t('next')),
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

class _QuestionPage extends StatelessWidget {
  final QuestionModel question;
  final LanguageProvider lang;
  final int? selected;
  final String langCode;
  final VoidCallback onToggleLang;
  final void Function(int option, bool isCorrect) onSelect;

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
                : () => onSelect(index, index == question.correctIndex),
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
              side: BorderSide(color: AppColors.accentPurple.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ],
    );
  }
}
