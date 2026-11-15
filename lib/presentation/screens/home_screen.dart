import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/state_views.dart';
import 'exam_screen.dart';
import 'practice_screen.dart';
import 'stats_screen.dart';
import 'wrong_questions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate(
            vi: 'Ôn Tập Flutter Song Ngữ',
            en: 'Flutter Bilingual Quiz',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => lang.toggleLanguage(),
            icon: const Icon(Icons.language, size: 20),
            label: Text(
              lang.isVietnamese ? 'EN' : 'VI',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context, quiz, lang),
    );
  }

  Widget _buildBody(
      BuildContext context, QuizProvider quiz, LanguageProvider lang) {
    if (quiz.state == QuizLoadingState.loading ||
        quiz.state == QuizLoadingState.initial) {
      return LoadingView(
        message: lang.translate(
          vi: 'Đang nạp 300 câu hỏi trắc nghiệm...',
          en: 'Loading 300 quiz questions...',
        ),
      );
    }

    if (quiz.state == QuizLoadingState.error) {
      return ErrorView(
        message: quiz.errorMessage ??
            lang.translate(
              vi: 'Có lỗi xảy ra khi nạp dữ liệu câu hỏi',
              en: 'An error occurred while loading question data',
            ),
        retryText: lang.translate(vi: 'Thử lại', en: 'Retry'),
        onRetry: () => quiz.initialize(),
      );
    }

    final total = quiz.allQuestions.length;
    final wrongCount = quiz.wrongQuestions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Status Card
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.flutter_dash,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lang.translate(
                      vi: 'Ngân Hàng 300 Câu Trắc Nghiệm',
                      en: 'Flutter 300 Question Bank',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang.translate(
                      vi: '20 Khối Kiến Thức • Song Ngữ Anh - Việt',
                      en: '20 Knowledge Blocks • Bilingual VI - EN',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: lang.translate(vi: 'Tổng câu', en: 'Total'),
                        value: '$total',
                      ),
                      _StatItem(
                        label: lang.translate(vi: 'Cần ôn lại', en: 'Need Review'),
                        value: '$wrongCount',
                        valueColor: wrongCount > 0 ? Colors.red.shade700 : null,
                      ),
                      _StatItem(
                        label: lang.translate(vi: 'Khối kiến thức', en: 'Blocks'),
                        value: '20',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Menu Title
          Text(
            lang.translate(vi: 'Chế độ học tập', en: 'Learning Modes'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Mode 1: Luyện tập theo khối
          _MenuCard(
            icon: Icons.menu_book_rounded,
            iconColor: Colors.blue.shade700,
            title: lang.translate(
              vi: 'Chế độ Luyện Tập',
              en: 'Practice Mode',
            ),
            subtitle: lang.translate(
              vi: 'Ôn tập tự do theo từng khối kiến thức, có giải thích ngay',
              en: 'Practice by block at your own pace with instant explanations',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PracticeScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Mode 2: Thi thử (Có đếm ngược)
          _MenuCard(
            icon: Icons.timer_outlined,
            iconColor: Colors.orange.shade800,
            title: lang.translate(
              vi: 'Chế độ Thi Thử (Mock Exam)',
              en: 'Mock Exam (Timed)',
            ),
            subtitle: lang.translate(
              vi: '20 câu ngẫu nhiên, đồng hồ đếm ngược 15 phút, chấm điểm',
              en: '20 random questions, 15-minute countdown, score report',
            ),
            badge: lang.translate(vi: 'Có bấm giờ', en: 'Timed'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Mode 3: Sổ tay câu sai
          _MenuCard(
            icon: Icons.bookmark_remove_rounded,
            iconColor: Colors.red.shade700,
            title: lang.translate(
              vi: 'Làm Lại Câu Sai',
              en: 'Review Incorrect Questions',
            ),
            subtitle: lang.translate(
              vi: 'Luyện lại các câu đã làm sai để củng cố kiến thức',
              en: 'Retake questions you answered incorrectly',
            ),
            badge: wrongCount > 0 ? '$wrongCount' : null,
            badgeColor: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const WrongQuestionsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Mode 4: Thống kê theo 20 khối
          _MenuCard(
            icon: Icons.bar_chart_rounded,
            iconColor: Colors.green.shade700,
            title: lang.translate(
              vi: 'Thống Kê Theo Khối Kiến Thức',
              en: 'Knowledge Block Statistics',
            ),
            subtitle: lang.translate(
              vi: 'Xem tỉ lệ chính xác và tiến độ trên 20 khối kiến thức',
              en: 'View accuracy rate across 20 Flutter knowledge blocks',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor ??
                Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor = Colors.orange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
