import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/gamification_provider.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/profile_settings_button.dart';
import '../widgets/state_views.dart';
import '../widgets/streak_card.dart';
import 'achievements_screen.dart';
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
    // Nullable lookup keeps existing HomeScreen tests/hosts without the feature provider working.
    final gamification = Provider.of<GamificationProvider?>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.translate(
            vi: 'Flutter Song Ngữ',
            en: 'Flutter Bilingual Quiz',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          ProfileSettingsButton(),
        ],
      ),
      body: _buildBody(context, quiz, lang, gamification),
    );
  }

  Widget _buildBody(
    BuildContext context,
    QuizProvider quiz,
    LanguageProvider lang,
    GamificationProvider? gamification,
  ) {
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
    final correctRate = total > 0
        ? (((total - wrongCount) / total) * 100).toStringAsFixed(0)
        : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modern Gradient Hero Card
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.flutter_dash,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.translate(
                              vi: 'Ngân Hàng 300 Câu Hỏi',
                              en: '300 Questions Bank',
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang.translate(
                              vi: '20 Khối Kiến Thức • Song Ngữ VI / EN',
                              en: '20 Blocks • Bilingual VI / EN',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Glassmorphism stats row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.quiz_outlined,
                        label: lang.translate(vi: 'Tổng câu', en: 'Total'),
                        value: '$total',
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      _StatItem(
                        icon: Icons.bookmark_remove_outlined,
                        label: lang.translate(vi: 'Cần ôn lại', en: 'Review'),
                        value: '$wrongCount',
                        valueColor: wrongCount > 0 ? const Color(0xFFFCA5A5) : null,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      _StatItem(
                        icon: Icons.trending_up_rounded,
                        label: lang.translate(vi: 'Chính xác', en: 'Accuracy'),
                        value: '$correctRate%',
                        valueColor: const Color(0xFF86EFAC),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (gamification != null) ...[
            StreakCard(
              progress: gamification.progress,
              currentStreak: gamification.currentStreak,
              levelProgress: gamification.levelProgress,
              languageCode: lang.code,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AchievementsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Section Header
          Text(
            lang.translate(vi: 'Chế độ học tập', en: 'Learning Modes'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Mode 1: Luyện tập theo khối
          _ModernMenuCard(
            icon: Icons.menu_book_rounded,
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            title: lang.translate(
              vi: 'Chế độ Luyện Tập',
              en: 'Practice Mode',
            ),
            subtitle: lang.translate(
              vi: 'Ôn tập tự do theo từng khối kiến thức, có giải thích & AI',
              en: 'Practice by block with explanations and AI tutor',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PracticeScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Mode 2: Trợ lý AI Chat
          _ModernMenuCard(
            icon: Icons.chat_bubble_outline_rounded,
            gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            title: lang.translate(
              vi: 'Trợ Lý AI Tutor',
              en: 'AI Tutor Chat',
            ),
            subtitle: lang.translate(
              vi: 'Hỏi đáp trực tiếp về Flutter/Dart, trả lời ngay',
              en: 'Ask Flutter/Dart questions and get instant answers',
            ),
            badge: 'AI',
            badgeColor: const Color(0xFF6366F1),
            onTap: () {
              Navigator.pushNamed(context, '/ai-chat');
            },
          ),
          const SizedBox(height: 12),

          // Mode 3: Thi thử (Có đếm ngược)
          _ModernMenuCard(
            icon: Icons.timer_outlined,
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
            title: lang.translate(
              vi: 'Chế độ Thi Thử (Mock Exam)',
              en: 'Mock Exam (Timed)',
            ),
            subtitle: lang.translate(
              vi: '20 câu ngẫu nhiên • Đồng hồ đếm ngược 15 phút',
              en: '20 random questions • 15-minute countdown',
            ),
            badge: lang.translate(vi: 'Bấm giờ', en: 'Timed'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Mode 3: Sổ tay câu sai
          _ModernMenuCard(
            icon: Icons.replay_circle_filled_rounded,
            gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            title: lang.translate(
              vi: 'Làm Lại Câu Sai',
              en: 'Review Incorrect Questions',
            ),
            subtitle: lang.translate(
              vi: 'Luyện lại các câu đã làm sai để củng cố kiến thức',
              en: 'Retake questions you answered incorrectly',
            ),
            badge: wrongCount > 0 ? '$wrongCount' : null,
            badgeColor: const Color(0xFFEF4444),
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
          _ModernMenuCard(
            icon: Icons.bar_chart_rounded,
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
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
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.75)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _ModernMenuCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final String? badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ModernMenuCard({
    required this.icon,
    required this.gradientColors,
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
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
                              fontSize: 15.5,
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
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
