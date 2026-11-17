import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/navigation/app_page_route.dart';
import '../presentation/providers/gamification_provider.dart';
import '../presentation/providers/language_provider.dart';
import '../presentation/providers/quiz_provider.dart';
import '../presentation/screens/achievements_screen.dart';
import '../presentation/screens/practice_screen.dart';
import '../presentation/screens/wrong_questions_screen.dart';
import '../presentation/widgets/language_button.dart';
import '../presentation/widgets/responsive_body.dart';
import '../presentation/widgets/state_views.dart';
import '../presentation/widgets/streak_card.dart';
import 'chon_de_screen.dart';
import 'chon_khoi_screen.dart';
import 'cua_toi_screen.dart';

class TrangChuScreen extends StatelessWidget {
  const TrangChuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.flutter_dash_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(lang.t('app_title')),
          ],
        ),
        actions: const [LanguageButton()],
      ),
      body: ResponsiveBody(child: _body(context, quiz, lang)),
    );
  }

  Widget _body(BuildContext context, QuizProvider quiz, LanguageProvider lang) {
    if (quiz.state == QuizLoadingState.loading ||
        quiz.state == QuizLoadingState.initial) {
      return LoadingView(message: lang.t('loading_questions'));
    }

    if (quiz.state == QuizLoadingState.error) {
      return ErrorView(
        message: quiz.errorMessage ?? lang.t('load_error'),
        retryText: lang.t('retry'),
        onRetry: quiz.initialize,
      );
    }

    final total = quiz.allQuestions.length;
    final blocks = quiz.groupedByBlock.length;
    final wrong = quiz.wrongQuestions.length;

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _WelcomeCard(
          title: lang.t('hero_title'),
          subtitle: lang.t('hero_subtitle'),
          blocksCount: blocks,
          questionsCount: total,
          wrongCount: wrong,
          blockLabel: lang.t('block').toLowerCase(),
          questionLabel: lang.t('questions'),
        ),
        // Gamification summary is shown on the app's active home screen.
        const SizedBox(height: 12),
        Consumer<GamificationProvider>(
          builder: (context, gamification, _) => StreakCard(
            progress: gamification.progress,
            currentStreak: gamification.currentStreak,
            levelProgress: gamification.levelProgress,
            languageCode: lang.code,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<GamificationProvider>(
          builder: (context, gamification, _) => _ModeCard(
            icon: Icons.bolt_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            title: lang.t('daily_challenge_title'),
            subtitle: gamification.dailyChallengeCompleted
                ? lang.t('daily_challenge_done')
                : lang.t('daily_challenge_pending'),
            badgeText: gamification.dailyChallengeCompleted ? null : '+50 XP',
            onTap: () {
              final questions = gamification.dailyChallengeQuestions(
                quiz.allQuestions,
              );
              Navigator.of(context).push(
                openAppPage(
                  PracticeScreen(
                    fixedQuestions: questions,
                    isDailyChallenge: true,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang.t('choose_mode'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$total ${lang.t('questions')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ModeCard(
          icon: Icons.auto_stories_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: lang.t('practice'),
          subtitle: lang.t('practice_hint'),
          badgeText: '$blocks ${lang.t('block')}',
          badgeColor: const Color(0xFFDBEAFE),
          badgeTextColor: const Color(0xFF1E40AF),
          onTap: () {
            Navigator.of(context).push(openAppPage(const ChonKhoiScreen()));
          },
        ),
        const SizedBox(height: 14),
        _ModeCard(
          icon: Icons.timer_outlined,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: lang.t('exam'),
          subtitle: lang.t('exam_hint'),
          badgeText: '40 ${lang.t('minutes')}',
          badgeColor: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFF92400E),
          onTap: () {
            Navigator.of(context).push(openAppPage(const ChonDeScreen()));
          },
        ),
        const SizedBox(height: 14),
        _ModeCard(
          icon: Icons.query_stats_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: lang.t('stats'),
          subtitle: lang.t('stats_hint'),
          badgeText: lang.t('overall'),
          badgeColor: const Color(0xFFD1FAE5),
          badgeTextColor: const Color(0xFF065F46),
          onTap: () {
            Navigator.of(context).push(openAppPage(const CuaToiScreen()));
          },
        ),
        const SizedBox(height: 14),
        _ModeCard(
          icon: Icons.bookmark_border_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: lang.t('wrong_book'),
          subtitle: wrong == 0
              ? lang.t('wrong_hint')
              : '$wrong · ${lang.t('wrong_hint')}',
          badgeText: wrong > 0 ? '$wrong ${lang.t('incorrect')}' : null,
          badgeColor: const Color(0xFFEDE9FE),
          badgeTextColor: const Color(0xFF5B21B6),
          onTap: () {
            Navigator.of(context)
                .push(openAppPage(const WrongQuestionsScreen()));
          },
        ),
        const SizedBox(height: 14),
        _ModeCard(
          icon: Icons.emoji_events_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF6F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: lang.t('achievements'),
          subtitle: lang.t('achievements_subtitle'),
          badgeColor: const Color(0xFFFFF3E0),
          badgeTextColor: const Color(0xFFE65100),
          onTap: () {
            Navigator.of(context).push(openAppPage(const AchievementsScreen()));
          },
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int blocksCount;
  final int questionsCount;
  final int wrongCount;
  final String blockLabel;
  final String questionLabel;

  const _WelcomeCard({
    required this.title,
    required this.subtitle,
    required this.blocksCount,
    required this.questionsCount,
    required this.wrongCount,
    required this.blockLabel,
    required this.questionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeaderStat(
                  icon: Icons.grid_view_rounded,
                  value: '$blocksCount',
                  label: blockLabel,
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                _HeaderStat(
                  icon: Icons.quiz_rounded,
                  value: '$questionsCount',
                  label: questionLabel,
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                _HeaderStat(
                  icon: Icons.bookmark_border_rounded,
                  value: '$wrongCount',
                  label: 'câu sai',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatefulWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(
                alpha: isDark ? 0.4 : 0.7,
              ),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () {
              setState(() => _pressed = false);
              widget.onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.colors.first.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (widget.badgeText != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? scheme.primaryContainer
                                      : (widget.badgeColor ??
                                            scheme.primaryContainer),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.badgeText!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? scheme.onPrimaryContainer
                                        : (widget.badgeTextColor ??
                                              scheme.onPrimaryContainer),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
