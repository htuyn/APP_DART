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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  correct ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
                  color: foreground,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          if (body.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: foreground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String optionLabel(int index) {
  const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
  if (index >= 0 && index < labels.length) return labels[index];
  return '${index + 1}';
}
