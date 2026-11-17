import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/navigation/app_page_route.dart';
import '../data/models/quiz_result_model.dart';
import '../data/models/thong_ke.dart';
import '../presentation/providers/language_provider.dart';
import '../presentation/providers/quiz_provider.dart';
import '../presentation/providers/stats_provider.dart';
import '../presentation/providers/theme_provider.dart';
import '../presentation/screens/practice_screen.dart';
import '../presentation/widgets/language_button.dart';
import '../presentation/widgets/responsive_body.dart';
import '../presentation/widgets/state_views.dart';

class CuaToiScreen extends StatefulWidget {
  const CuaToiScreen({super.key});

  @override
  State<CuaToiScreen> createState() => _CuaToiScreenState();
}

class _CuaToiScreenState extends State<CuaToiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StatsProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final quiz = context.watch<QuizProvider>();
    final stats = context.watch<StatsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('mine')),
        actions: const [LanguageButton()],
      ),
      body: ResponsiveBody(child: _body(context, quiz, stats, lang)),
    );
  }

  Widget _body(
    BuildContext context,
    QuizProvider quiz,
    StatsProvider stats,
    LanguageProvider lang,
  ) {
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

    final blocks = stats.calculateBlockStats(
      allQuestions: quiz.allQuestions,
      wrongIds: quiz.wrongQuestionIds,
      langCode: lang.code,
    );
    final summary = QuizHistorySummary.fromResults(stats.history);
    final totalQuestions = blocks.fold<int>(0, (sum, item) => sum + item.totalQuestions);
    final totalCorrect = blocks.fold<int>(0, (sum, item) => sum + item.correctCount);
    final overall = totalQuestions == 0 ? 0.0 : (totalCorrect / totalQuestions) * 100;

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        const _ProfileCard(),
        const SizedBox(height: 16),
        _OverviewCard(
          title: lang.t('overall'),
          accuracyLabel: lang.t('accuracy'),
          correctLabel: lang.t('correct'),
          incorrectLabel: lang.t('incorrect'),
          rate: overall,
          correct: totalCorrect,
          incorrect: totalQuestions - totalCorrect,
          blocks: blocks.length,
          blockLabel: lang.t('block'),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(lang.t('certificates_title')),
                subtitle: Text(lang.t('certificates_subtitle')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(
                  AppPageRoutes.certificates,
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.track_changes_outlined),
                title: Text(lang.t('course_progress_title')),
                subtitle: Text(lang.t('course_requirements')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(
                  AppPageRoutes.courseProgress,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          lang.t('history'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _HistorySummary(
          attemptsLabel: lang.t('attempts'),
          bestLabel: lang.t('best'),
          averageLabel: lang.t('average'),
          summary: summary,
        ),
        const SizedBox(height: 12),
        if (stats.history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t('no_history'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang.t('no_history_hint'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
        else
          for (final item in stats.history.reversed.take(6)) ...[
            _HistoryTile(
              resultTime: _formatDate(item.timestamp),
              result: item,
              questionLabel: lang.t('questions'),
            ),
            const SizedBox(height: 8),
          ],
        if (blocks.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            lang.t('chart'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: blocks.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) => _BarColumn(stat: blocks[index]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            lang.t('detail'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final stat in blocks) ...[
            _StatRow(
              stat: stat,
              correctLabel: lang.t('correct'),
              incorrectLabel: lang.t('incorrect'),
              onTap: () {
                Navigator.of(context).push(
                  openAppPage(PracticeScreen(initialBlockId: stat.blockId)),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final theme = context.watch<ThemeProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('learner'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.t('hero_subtitle'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                Icon(Icons.language_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  lang.t('language'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Tiếng Việt'),
                  selected: lang.isVietnamese,
                  onSelected: (selected) {
                    if (selected) lang.setLanguage(AppLanguage.vi);
                  },
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('English'),
                  selected: !lang.isVietnamese,
                  onSelected: (selected) {
                    if (selected) lang.setLanguage(AppLanguage.en);
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.contrast_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  lang.t('appearance'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.brightness_auto_rounded, size: 16),
                  label: Text(lang.t('theme_system')),
                  selected: theme.mode == ThemeMode.system,
                  onSelected: (selected) {
                    if (selected) theme.setMode(ThemeMode.system);
                  },
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.light_mode_rounded, size: 16),
                  label: Text(lang.t('theme_light')),
                  selected: theme.mode == ThemeMode.light,
                  onSelected: (selected) {
                    if (selected) theme.setMode(ThemeMode.light);
                  },
                ),
                ChoiceChip(
                  avatar: const Icon(Icons.dark_mode_rounded, size: 16),
                  label: Text(lang.t('theme_dark')),
                  selected: theme.mode == ThemeMode.dark,
                  onSelected: (selected) {
                    if (selected) theme.setMode(ThemeMode.dark);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  final String attemptsLabel;
  final String bestLabel;
  final String averageLabel;
  final QuizHistorySummary summary;

  const _HistorySummary({
    required this.attemptsLabel,
    required this.bestLabel,
    required this.averageLabel,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniStat(
          label: attemptsLabel,
          value: '${summary.attemptCount}',
          icon: Icons.history_rounded,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          label: bestLabel,
          value: '${summary.bestPercentage.toStringAsFixed(0)}%',
          icon: Icons.emoji_events_rounded,
        ),
        const SizedBox(width: 10),
        _MiniStat(
          label: averageLabel,
          value: '${summary.averagePercentage.toStringAsFixed(0)}%',
          icon: Icons.insights_rounded,
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String resultTime;
  final QuizResultModel result;
  final String questionLabel;

  const _HistoryTile({
    required this.resultTime,
    required this.result,
    required this.questionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final score = result.score;
    final total = result.totalQuestions;
    final percent = result.percentage.toStringAsFixed(0);
    final passed = result.percentage >= 60;

    return Card(
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
        ),
        leading: CircleAvatar(
          backgroundColor: (passed ? AppColors.success : AppColors.error)
              .withValues(alpha: 0.14),
          foregroundColor: passed ? AppColors.success : AppColors.error,
          child: Icon(passed ? Icons.check_rounded : Icons.close_rounded, size: 20),
        ),
        title: Text(
          '$score/$total $questionLabel · $percent%',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(resultTime, style: Theme.of(context).textTheme.bodySmall),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (passed ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            passed ? 'PASSED' : 'FAILED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: passed ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final String accuracyLabel;
  final String correctLabel;
  final String incorrectLabel;
  final double rate;
  final int correct;
  final int incorrect;
  final int blocks;
  final String blockLabel;

  const _OverviewCard({
    required this.title,
    required this.accuracyLabel,
    required this.correctLabel,
    required this.incorrectLabel,
    required this.rate,
    required this.correct,
    required this.incorrect,
    required this.blocks,
    required this.blockLabel,
  });

  @override
  Widget build(BuildContext context) {
    final percent = rate.clamp(0.0, 100.0);
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    color: const Color(0xFF86EFAC),
                  ),
                ),
                Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  accuracyLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$correctLabel: $correct',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$incorrectLabel: $incorrect',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final BlockStat stat;

  const _BarColumn({required this.stat});

  @override
  Widget build(BuildContext context) {
    final rate = stat.accuracyRate.clamp(0.0, 100.0);
    final color = _rateColor(rate);
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          Text(
            '${rate.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: (rate / 100).clamp(0.08, 1.0),
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${stat.blockId}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final BlockStat stat;
  final String correctLabel;
  final String incorrectLabel;
  final VoidCallback onTap;

  const _StatRow({
    required this.stat,
    required this.correctLabel,
    required this.incorrectLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rate = stat.accuracyRate.clamp(0.0, 100.0);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppMetrics.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${stat.blockId}. ${stat.blockTitle}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _rateColor(rate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: rate / 100,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: _rateColor(rate),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$correctLabel ${stat.correctCount}/${stat.totalQuestions} · $incorrectLabel ${stat.wrongQuestions}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _rateColor(double rate) {
  if (rate >= 80) return AppColors.success;
  if (rate >= 50) return AppColors.warning;
  return AppColors.error;
}
