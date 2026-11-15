import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/question_model.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/option_tile.dart';
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
        title: Text(
          lang.translate(
            vi: 'Sổ Tay Câu Sai (${wrongList.length})',
            en: 'Incorrect Questions (${wrongList.length})',
          ),
        ),
      ),
      body: wrongList.isEmpty
          ? EmptyView(
              icon: Icons.check_circle_outline_rounded,
              title: lang.translate(
                vi: 'Không có câu sai nào!',
                en: 'No Incorrect Questions!',
              ),
              message: lang.translate(
                vi: 'Bạn đã làm đúng tất cả các câu hỏi hoặc chưa làm bài thi nào.',
                en: 'You have answered all questions correctly or haven\'t taken any tests yet.',
              ),
              actionText: lang.translate(vi: 'Về trang chủ', en: 'Back to Home'),
              onAction: () => Navigator.pop(context),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: wrongList.length,
              itemBuilder: (context, index) {
                final q = wrongList[index];
                return _buildWrongQuestionItem(q, lang, quiz);
              },
            ),
    );
  }

  Widget _buildWrongQuestionItem(
      QuestionModel q, LanguageProvider lang, QuizProvider quiz) {
    final currentLang = _langOverrides[q.id] ?? lang.code;
    final isAnswered = _selectedAnswers.containsKey(q.id);
    final userChoice = _selectedAnswers[q.id];
    final options = q.getOptions(currentLang);
    final labels = ['A', 'B', 'C', 'D'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${q.id} • ${q.blockName.getText(currentLang)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.translate, size: 18),
                  tooltip: lang.translate(
                      vi: 'Đổi ngôn ngữ câu này', en: 'Toggle language'),
                  onPressed: () {
                    setState(() {
                      _langOverrides[q.id] = currentLang == 'vi' ? 'en' : 'vi';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              q.question.getText(currentLang),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
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
                label: labels[optIdx],
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
                            question: q, isCorrect: isCorrect);
                      },
              );
            }),
            if (isAnswered) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: userChoice == q.correctIndex
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  userChoice == q.correctIndex
                      ? lang.translate(
                          vi: 'Tuyệt vời! Câu hỏi này đã được xóa khỏi danh sách câu sai.',
                          en: 'Awesome! This question is now removed from your incorrect list.',
                        )
                      : '${lang.translate(vi: "Giải thích:", en: "Explanation:")} ${q.explanation.getText(currentLang)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: userChoice == q.correctIndex
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
