import 'package:material_ui/material_ui.dart';

import '../../core/l10n/app_strings.dart';
import '../../domain/gamification/badge_catalog.dart';

/// Congratulations dialog for badges unlocked by the latest exam.
class BadgeUnlockedDialog extends StatelessWidget {
  const BadgeUnlockedDialog({
    super.key,
    required this.badges,
    required this.languageCode,
  });

  final List<BadgeDefinition> badges;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Text('🎉', style: TextStyle(fontSize: 38)),
      title: Text(
        AppStrings.text(languageCode, 'badge_unlocked_dialog_title'),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.text(languageCode, 'badge_unlocked_dialog_body'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            for (final badge in badges)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(badge.icon, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.text(languageCode, badge.titleKey),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            AppStrings.text(languageCode, badge.descriptionKey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.text(languageCode, 'close')),
        ),
      ],
    );
  }
}
