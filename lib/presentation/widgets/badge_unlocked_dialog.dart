import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../domain/gamification/badge_catalog.dart';

/// Congratulations dialog for badges unlocked by the latest exam.
class BadgeUnlockedDialog extends StatefulWidget {
  const BadgeUnlockedDialog({
    super.key,
    required this.badges,
    required this.languageCode,
  });

  final List<BadgeDefinition> badges;
  final String languageCode;

  @override
  State<BadgeUnlockedDialog> createState() => _BadgeUnlockedDialogState();
}

class _BadgeUnlockedDialogState extends State<BadgeUnlockedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    unawaited(HapticFeedback.mediumImpact().catchError((Object _) {}));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _copyAchievement() async {
    final badgeNames = widget.badges
        .map((badge) => AppStrings.text(widget.languageCode, badge.titleKey))
        .join(', ');
    final message =
        '${AppStrings.text(widget.languageCode, 'badge_share_message')} $badgeNames';
    await Clipboard.setData(ClipboardData(text: message));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppStrings.text(widget.languageCode, 'badge_share_copied'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
      child: AlertDialog(
        icon: const Text('🎉', style: TextStyle(fontSize: 38)),
        title: Text(
          AppStrings.text(widget.languageCode, 'badge_unlocked_dialog_title'),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.text(widget.languageCode, 'badge_unlocked_dialog_body'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              for (final badge in widget.badges)
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
                              AppStrings.text(widget.languageCode, badge.titleKey),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              AppStrings.text(
                                widget.languageCode,
                                badge.descriptionKey,
                              ),
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
          TextButton.icon(
            onPressed: _copyAchievement,
            icon: const Icon(Icons.share_rounded),
            label: Text(AppStrings.text(widget.languageCode, 'share')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.text(widget.languageCode, 'close')),
          ),
        ],
      ),
    );
  }
}
