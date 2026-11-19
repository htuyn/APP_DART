import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ExplanationCard extends StatelessWidget {
  final bool correct;
  final String title;
  final String body;

  const ExplanationCard({
    super.key,
    required this.correct,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = correct ? AppColors.success : AppColors.warning;
    final background = isDark
        ? tone.withValues(alpha: 0.18)
        : (correct ? AppColors.successLight : AppColors.warningLight);
    final foreground = isDark
        ? (correct ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D))
        : (correct ? const Color(0xFF065F46) : const Color(0xFF92400E));

    // Determine which icon to show based on state
    final IconData headerIcon = correct
        ? Icons.check_circle_rounded
        : Icons.lightbulb_rounded;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tone.withValues(alpha: 0.45), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: tone.withValues(alpha: isDark ? 0.12 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    headerIcon,
                    color: foreground,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: foreground,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (body.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(
                color: tone.withValues(alpha: 0.2),
                height: 1,
                thickness: 1,
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.52,
                  color: foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String optionLabel(int index) {
  const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
  if (index >= 0 && index < labels.length) return labels[index];
  return '${index + 1}';
}
