import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../providers/gamification_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/badge_tile.dart';
import '../widgets/streak_card.dart';

/// Streak overview and badge collection.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>();
    final language = context.watch<LanguageProvider>();
    final code = language.code;
    final progress = gamification.progress;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.text(code, 'achievements')),
      ),
      body: gamification.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  AppStrings.text(code, 'achievements_subtitle'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                StreakCard(
                  progress: progress,
                  currentStreak: gamification.currentStreak,
                  levelProgress: gamification.levelProgress,
                  languageCode: code,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.text(code, 'daily_goal_title'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final goal in const [5, 10, 20]) ...[
                      if (goal != 5) const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: progress.dailyGoal == goal
                              ? FilledButton(
                                  key: ValueKey('daily-goal-$goal'),
                                  onPressed: () async =>
                                      gamification.updateDailyGoal(goal),
                                  child: Text(
                                    '$goal ${AppStrings.text(code, 'daily_goal_questions')}',
                                  ),
                                )
                              : OutlinedButton(
                                  key: ValueKey('daily-goal-$goal'),
                                  onPressed: () async =>
                                      gamification.updateDailyGoal(goal),
                                  child: Text(
                                    '$goal ${AppStrings.text(code, 'daily_goal_questions')}',
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _ProgressGrid(
                  languageCode: code,
                  values: [
                    (
                      'today_answered',
                      progress.todayAnswered,
                      Icons.today_rounded,
                    ),
                    (
                      'total_answered',
                      progress.totalAnswered,
                      Icons.quiz_outlined,
                    ),
                    (
                      'exam_count',
                      progress.examCount,
                      Icons.assignment_turned_in_outlined,
                    ),
                    (
                      'perfect_count',
                      progress.perfectCount,
                      Icons.workspace_premium_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.text(code, 'badges_title'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760
                        ? 4
                        : constraints.maxWidth >= 480
                            ? 3
                            : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gamification.badges.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        // Extra height prevents localized badge descriptions from clipping.
                        mainAxisExtent: 250,
                      ),
                      itemBuilder: (context, index) {
                        final badge = gamification.badges[index];
                        return BadgeTile(
                          badge: badge,
                          progress: progress,
                          languageCode: code,
                          unlockedDate: progress.unlockedBadges[badge.id],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _ProgressGrid extends StatelessWidget {
  const _ProgressGrid({
    required this.languageCode,
    required this.values,
  });

  final String languageCode;
  final List<(String, int, IconData)> values;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 94,
      ),
      itemBuilder: (context, index) {
        final (labelKey, value, icon) = values[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.text(languageCode, labelKey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '$value',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
