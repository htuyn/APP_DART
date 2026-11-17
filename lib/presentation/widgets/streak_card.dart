import 'package:material_ui/material_ui.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/models/gamification_model.dart';
import '../../domain/gamification/gamification_engine.dart';

/// Compact streak summary shared by Home and Achievements.
class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.progress,
    required this.currentStreak,
    required this.levelProgress,
    required this.languageCode,
    this.onTap,
  });

  final GamificationModel progress;
  final int currentStreak;
  final LevelProgress levelProgress;
  final String languageCode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = AppStrings.text(languageCode, 'streak_title');
    final streakLabel = AppStrings.text(languageCode, 'streak_days');
    final bestLabel = AppStrings.text(languageCode, 'streak_best');
    final dailyGoalLabel = AppStrings.text(languageCode, 'daily_goal_today');
    final levelLabel = AppStrings.text(languageCode, 'level_label');
    final xpPointsLabel = AppStrings.text(languageCode, 'xp_points');
    final dailyGoal = progress.dailyGoal.clamp(1, 9999);
    final todayProgress = progress.todayAnswered.clamp(0, dailyGoal);
    final semantics = '$title: $currentStreak $streakLabel. '
        '$bestLabel: ${progress.longestStreak}. '
        '$todayProgress/$dailyGoal $dailyGoalLabel.';

    return Semantics(
      container: true,
      button: onTap != null,
      label: semantics,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                const Text('🔥', style: TextStyle(fontSize: 34)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentStreak $streakLabel',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text('$bestLabel: ${progress.longestStreak}'),
                      const SizedBox(height: 4),
                      Text('$todayProgress/$dailyGoal $dailyGoalLabel'),
                    ],
                  ),
                ),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: todayProgress / dailyGoal,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      Text(
                        '$todayProgress/$dailyGoal',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                    if (onTap != null) const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$levelLabel ${levelProgress.level} · '
                        '${AppStrings.text(languageCode, levelProgress.titleKey)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text('${progress.xp} $xpPointsLabel'),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  key: const ValueKey('xp-level-progress'),
                  value: levelProgress.progress,
                ),
                const SizedBox(height: 4),
                Text(
                  '${levelProgress.currentLevelXp}/${levelProgress.xpForNextLevel} $xpPointsLabel',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
