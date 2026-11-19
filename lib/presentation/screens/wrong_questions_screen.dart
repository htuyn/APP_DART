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

class WrongQuestionsScreen extends StatefulWidget {
  const WrongQuestionsScreen({super.key});

  @override
  State<WrongQuestionsScreen> createState() => _WrongQuestionsScreenState();
}

class _WrongQuestionsScreenState extends State<WrongQuestionsScreen> {
  final Map<String, int> _selectedAnswers = {};
  final Map<String, String> _langOverrides = {};

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();
    final wrongList = quiz.wrongQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text('${lang.t('wrong_title')} (${wrongList.length})'),
        actions: const [LanguageButton()],
      ),
      body: ResponsiveBody(
        child: wrongList.isEmpty
            ? EmptyView(
                icon: Icons.check_circle_outline_rounded,
                title: lang.t('wrong_empty'),
                message: lang.t('wrong_empty_hint'),
                actionText: lang.t('go_home'),
                onAction: () => Navigator.pop(context),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: wrongList.length,
                itemBuilder: (context, index) {
                  final q = wrongList[index];
                  return _buildWrongQuestionItem(q, lang, quiz);
                },
              ),
      ),
    );
  }

  Widget _buildWrongQuestionItem(
      QuestionModel q, LanguageProvider lang, QuizProvider quiz) {
    final currentLang = _langOverrides[q.id] ?? lang.code;
    final isAnswered = _selectedAnswers.containsKey(q.id);
    final userChoice = _selectedAnswers[q.id];
    final options = q.getOptions(currentLang);
    final theme = Theme.of(context);

    final isBookmarked = quiz.isBookmarked(q.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${q.id} • ${q.blockName.getText(currentLang)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                Material(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _langOverrides[q.id] = currentLang == 'vi' ? 'en' : 'vi';
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.translate_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: isBookmarked
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => quiz.toggleBookmark(q.id),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 18,
                        color: isBookmarked
                            ? AppColors.warning
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              q.question.getText(currentLang),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.46,
              ),
            ),
            const SizedBox(height: 14),
            ...List.generate(options.length, (optIdx) {
              OptionState state = OptionState.idle;
              if (isAnswered) {
                if (optIdx == q.correctIndex) {
                  state = OptionState.correct;
                } else if (optIdx == userChoice) {
                  state = OptionState.wrong;
                }
              }

              return OptionTile(
                label: optionLabel(optIdx),
                text: options[optIdx],
                state: state,
                onTap: isAnswered
                    ? null
                    : () async {
                        final isCorrect = optIdx == q.correctIndex;
                        setState(() {
                          _selectedAnswers[q.id] = optIdx;
                        });
                        await quiz.recordAnswer(
                          question: q,
                          isCorrect: isCorrect,
                        );
                      },
              );
            }),
            if (isAnswered) ...[
              const SizedBox(height: 12),
              ExplanationCard(
                correct: userChoice == q.correctIndex,
                title: userChoice == q.correctIndex
                    ? lang.t('correct_bang')
                    : lang.t('explanation'),
                body: userChoice == q.correctIndex
                    ? lang.t('removed_wrong')
                    : q.explanation.getText(currentLang),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  AiTutorSheet.show(
                    context,
                    question: q,
                    userChoiceIndex: userChoice,
                  );
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                label: Text(lang.t('ask_ai_tricky')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentPurple,
                  side: BorderSide(
                      color: AppColors.accentPurple.withValues(alpha: 0.45)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
