import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/gamification_provider.dart';
import '../providers/language_provider.dart';
import '../providers/quiz_provider.dart';
import '../widgets/state_views.dart';
import '../widgets/streak_card.dart';
import 'achievements_screen.dart';
import 'diep_exam_screen.dart';
import 'diep_practice_screen.dart';
import 'stats_screen.dart';
import 'diep_wrong_questions_screen.dart';

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
            vi: 'Flutter Song NgÃ†Â°ÃŒÆ’',
            en: 'Flutter Bilingual Quiz',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Icon(Icons.language, size: 16),
              label: Text(
                lang.isVietnamese ? 'EN' : 'VI',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => lang.toggleLanguage(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
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
          vi: 'Ã„Âang nÃ¡ÂºÂ¡p 300 cÃƒÂ¢u hÃ¡Â»Âi trÃ¡ÂºÂ¯c nghiÃ¡Â»â€¡m...',
          en: 'Loading 300 quiz questions...',
        ),
      );
    }

    if (quiz.state == QuizLoadingState.error) {
      return ErrorView(
        message: quiz.errorMessage ??
            lang.translate(
              vi: 'CÃƒÂ³ lÃ¡Â»â€”i xÃ¡ÂºÂ£y ra khi nÃ¡ÂºÂ¡p dÃ¡Â»Â¯ liÃ¡Â»â€¡u cÃƒÂ¢u hÃ¡Â»Âi',
              en: 'An error occurred while loading question data',
            ),
        retryText: lang.translate(vi: 'ThÃ¡Â»Â­ lÃ¡ÂºÂ¡i', en: 'Retry'),
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
                              vi: 'NgÃƒÂ¢n HÃƒÂ ng 300 CÃƒÂ¢u HÃ¡Â»Âi',
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
                              vi: '20 KhÃ¡Â»â€˜i KiÃ¡ÂºÂ¿n ThÃ¡Â»Â©c Ã¢â‚¬Â¢ Song NgÃ¡Â»Â¯ VI / EN',
                              en: '20 Blocks Ã¢â‚¬Â¢ Bilingual VI / EN',
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
                        label: lang.translate(vi: 'TÃ¡Â»â€¢ng cÃƒÂ¢u', en: 'Total'),
                        value: '$total',
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      _StatItem(
                        icon: Icons.bookmark_remove_outlined,
                        label: lang.translate(vi: 'CÃ¡ÂºÂ§n ÃƒÂ´n lÃ¡ÂºÂ¡i', en: 'Review'),
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
                        label: lang.translate(vi: 'ChÃƒÂ­nh xÃƒÂ¡c', en: 'Accuracy'),
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
            lang.translate(vi: 'ChÃ¡ÂºÂ¿ Ã„â€˜Ã¡Â»â„¢ hÃ¡Â»Âc tÃ¡ÂºÂ­p', en: 'Learning Modes'),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Mode 1: LuyÃ¡Â»â€¡n tÃ¡ÂºÂ­p theo khÃ¡Â»â€˜i
          _ModernMenuCard(
            icon: Icons.menu_book_rounded,
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            title: lang.translate(
              vi: 'ChÃ¡ÂºÂ¿ Ã„â€˜Ã¡Â»â„¢ LuyÃ¡Â»â€¡n TÃ¡ÂºÂ­p',
              en: 'Practice Mode',
            ),
            subtitle: lang.translate(
              vi: 'Ãƒâ€n tÃ¡ÂºÂ­p tÃ¡Â»Â± do theo tÃ¡Â»Â«ng khÃ¡Â»â€˜i kiÃ¡ÂºÂ¿n thÃ¡Â»Â©c, cÃƒÂ³ giÃ¡ÂºÂ£i thÃƒÂ­ch & AI',
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

          // Mode 2: Thi thÃ¡Â»Â­ (CÃƒÂ³ Ã„â€˜Ã¡ÂºÂ¿m ngÃ†Â°Ã¡Â»Â£c)
          _ModernMenuCard(
            icon: Icons.timer_outlined,
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
            title: lang.translate(
              vi: 'ChÃ¡ÂºÂ¿ Ã„â€˜Ã¡Â»â„¢ Thi ThÃ¡Â»Â­ (Mock Exam)',
              en: 'Mock Exam (Timed)',
            ),
            subtitle: lang.translate(
              vi: '20 cÃƒÂ¢u ngÃ¡ÂºÂ«u nhiÃƒÂªn Ã¢â‚¬Â¢ Ã„ÂÃ¡Â»â€œng hÃ¡Â»â€œ Ã„â€˜Ã¡ÂºÂ¿m ngÃ†Â°Ã¡Â»Â£c 15 phÃƒÂºt',
              en: '20 random questions Ã¢â‚¬Â¢ 15-minute countdown',
            ),
            badge: lang.translate(vi: 'BÃ¡ÂºÂ¥m giÃ¡Â»Â', en: 'Timed'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Mode 3: SÃ¡Â»â€¢ tay cÃƒÂ¢u sai
          _ModernMenuCard(
            icon: Icons.replay_circle_filled_rounded,
            gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            title: lang.translate(
              vi: 'LÃƒÂ m LÃ¡ÂºÂ¡i CÃƒÂ¢u Sai',
              en: 'Review Incorrect Questions',
            ),
            subtitle: lang.translate(
              vi: 'LuyÃ¡Â»â€¡n lÃ¡ÂºÂ¡i cÃƒÂ¡c cÃƒÂ¢u Ã„â€˜ÃƒÂ£ lÃƒÂ m sai Ã„â€˜Ã¡Â»Æ’ cÃ¡Â»Â§ng cÃ¡Â»â€˜ kiÃ¡ÂºÂ¿n thÃ¡Â»Â©c',
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

          // Mode 4: ThÃ¡Â»â€˜ng kÃƒÂª theo 20 khÃ¡Â»â€˜i
          _ModernMenuCard(
            icon: Icons.bar_chart_rounded,
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            title: lang.translate(
              vi: 'ThÃ¡Â»â€˜ng KÃƒÂª Theo KhÃ¡Â»â€˜i KiÃ¡ÂºÂ¿n ThÃ¡Â»Â©c',
              en: 'Knowledge Block Statistics',
            ),
            subtitle: lang.translate(
              vi: 'Xem tÃ¡Â»â€° lÃ¡Â»â€¡ chÃƒÂ­nh xÃƒÂ¡c vÃƒÂ  tiÃ¡ÂºÂ¿n Ã„â€˜Ã¡Â»â„¢ trÃƒÂªn 20 khÃ¡Â»â€˜i kiÃ¡ÂºÂ¿n thÃ¡Â»Â©c',
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
