import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/question_model.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/ai_tutor_sheet.dart';
import '../widgets/option_tile.dart';
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

  // Track user selections for each question in this session:
  // questionId -> selectedOptionIndex
  final Map<String, int> _selectedAnswers = {};

  // Override question language if user wants to toggle language for a specific question
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate(vi: 'Chế độ Luyện Tập', en: 'Practice Mode'),
        ),
        actions: [
          // Filter block dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedBlockId,
              icon: const Icon(Icons.filter_list),
              onChanged: (newBlock) {
                if (newBlock == null) return;
                setState(() {
                  _selectedBlockId = newBlock;
                  _currentIndex = 0;
                  _selectedAnswers.clear();
                });
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 0,
                  child: Text(
                    lang.translate(vi: 'Tất cả 20 khối', en: 'All 20 blocks'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...List.generate(20, (index) {
                  final bId = index + 1;
                  return DropdownMenuItem(
                    value: bId,
                    child: Text(
                      lang.translate(
                        vi: 'Khối $bId',
                        en: 'Block $bId',
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: questions.isEmpty
          ? EmptyView(
              title: lang.translate(
                vi: 'Không có câu hỏi nào',
                en: 'No questions found',
              ),
              message: lang.translate(
                vi: 'Khối kiến thức này chưa có dữ liệu.',
                en: 'This knowledge block has no data yet.',
              ),
              actionText: lang.translate(vi: 'Về trang chủ', en: 'Go home'),
              onAction: () => Navigator.pop(context),
            )
          : Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: (questions.isEmpty)
                      ? 0
                      : (_currentIndex + 1) / questions.length,
                  backgroundColor: Colors.grey.shade200,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${lang.translate(vi: "Câu", en: "Question")} ${_currentIndex + 1}/${questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        questions[_currentIndex].level,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                      return _buildQuestionCard(q, lang, quiz);
                    },
                  ),
                ),
                // Bottom Navigation controls
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
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            child: Text(lang.translate(
                                vi: 'Câu trước', en: 'Previous')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentIndex < questions.length - 1
                                ? () {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            child: Text(
                                lang.translate(vi: 'Câu tiếp', en: 'Next')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuestionCard(
      QuestionModel q, LanguageProvider lang, QuizProvider quiz) {
    final currentQuesLang = _questionLangOverride[q.id] ?? lang.code;
    final isSelected = _selectedAnswers.containsKey(q.id);
    final selectedOption = _selectedAnswers[q.id];

    final options = q.getOptions(currentQuesLang);
    final explanation = q.explanation.getText(currentQuesLang);
    final labels = ['A', 'B', 'C', 'D'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Block Tag & Language Toggle for this question
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  q.blockName.getText(currentQuesLang),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: lang.translate(
                  vi: 'Chuyển ngôn ngữ câu này',
                  en: 'Toggle language for this question',
                ),
                icon: const Icon(Icons.translate, size: 20),
                onPressed: () {
                  setState(() {
                    final nextLang = currentQuesLang == 'vi' ? 'en' : 'vi';
                    _questionLangOverride[q.id] = nextLang;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Question Text
          Text(
            q.question.getText(currentQuesLang),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ...List.generate(options.length, (optIdx) {
            OptionState state = OptionState.idle;

            if (isSelected) {
              if (optIdx == q.correctIndex) {
                state = OptionState.correct;
              } else if (optIdx == selectedOption) {
                state = OptionState.wrong;
              }
            }

            return OptionTile(
              label: labels[optIdx],
              text: options[optIdx],
              state: state,
              onTap: isSelected
                  ? null
                  : () {
                      final isCorrect = optIdx == q.correctIndex;
                      setState(() {
                        _selectedAnswers[q.id] = optIdx;
                      });
                      quiz.recordAnswer(question: q, isCorrect: isCorrect);
                    },
            );
          }),

          // Explanation Box (shown after answer)
          if (isSelected) ...[
            const SizedBox(height: 16),
            Card(
              color: selectedOption == q.correctIndex
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selectedOption == q.correctIndex
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          selectedOption == q.correctIndex
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: selectedOption == q.correctIndex
                              ? Colors.green.shade800
                              : Colors.orange.shade900,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedOption == q.correctIndex
                              ? lang.translate(vi: 'Chính xác!', en: 'Correct!')
                              : lang.translate(vi: 'Giải thích:', en: 'Explanation:'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selectedOption == q.correctIndex
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade900,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  AiTutorSheet.show(
                    context,
                    question: q,
                    userChoiceIndex: selectedOption,
                  );
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  lang.translate(
                    vi: '🤖 Hỏi Gia Sư AI Giải Thích Thêm',
                    en: '🤖 Ask AI Tutor for In-Depth Help',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  foregroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
