import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/models/gamification_model.dart';
import '../../domain/gamification/badge_catalog.dart';

/// Accessible tile showing a locked or unlocked badge and its earned date.
class BadgeTile extends StatelessWidget {
  const BadgeTile({
    super.key,
    required this.badge,
    required this.progress,
    required this.languageCode,
    this.unlockedDate,
  });

  final BadgeDefinition badge;
  final GamificationModel progress;
  final String languageCode;
  final String? unlockedDate;

  bool get isUnlocked => unlockedDate != null;

  @override
  Widget build(BuildContext context) {
    final title = AppStrings.text(languageCode, badge.titleKey);
    final description = AppStrings.text(languageCode, badge.descriptionKey);
    final status = AppStrings.text(
      languageCode,
      isUnlocked ? 'badge_unlocked' : 'badge_locked',
    );
    final earnedOn = unlockedDate == null
        ? ''
        : '${AppStrings.text(languageCode, 'badge_earned_on')}: $unlockedDate';
    final (current, target) = badge.progressFor(progress);
    final semantics =
        '$title. $description. $status${isUnlocked ? '' : '. $current/$target'}'
        '${earnedOn.isEmpty ? '' : '. $earnedOn'}';

    return Semantics(
      container: true,
      label: semantics,
      child: Card(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: isUnlocked ? 1 : 0.38,
                  child: Text(badge.icon, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  unlockedDate == null
                      ? status
                      : '$status · $unlockedDate',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isUnlocked
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (!isUnlocked) ...[
                  const SizedBox(height: 6),
                  Text('$current/$target'),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: target == 0 ? 0 : current / target,
                    semanticsLabel: '$title $current/$target',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
