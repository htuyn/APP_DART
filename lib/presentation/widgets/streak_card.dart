import 'package:material_ui/material_ui.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/models/gamification_model.dart';

/// Compact streak summary shared by Home and Achievements.
class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.progress,
    required this.currentStreak,
    required this.languageCode,
    this.onTap,
  });

  final GamificationModel progress;
  final int currentStreak;
  final String languageCode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = AppStrings.text(languageCode, 'streak_title');
    final streakLabel = AppStrings.text(languageCode, 'streak_days');
    final bestLabel = AppStrings.text(languageCode, 'streak_best');
    final semantics = '$title: $currentStreak $streakLabel. '
        '$bestLabel: ${progress.longestStreak}.';

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
            child: Row(
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
                    ],
                  ),
                ),
                if (onTap != null) const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
