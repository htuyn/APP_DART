import 'package:flutter/material.dart';

enum OptionState { idle, selected, correct, wrong }

class OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final OptionState state;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.label,
    required this.text,
    this.state = OptionState.idle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color borderColor;
    Color bgColor;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    Color labelBg;
    Color labelText;
    IconData? trailingIcon;
    Color iconColor = Colors.transparent;
    double borderWidth = 1.2;

    switch (state) {
      case OptionState.idle:
        borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300;
        bgColor = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
        labelBg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100;
        labelText = isDark ? Colors.white70 : Colors.black87;
        break;
      case OptionState.selected:
        borderColor = Theme.of(context).colorScheme.primary;
        bgColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
        labelBg = Theme.of(context).colorScheme.primary;
        labelText = Colors.white;
        borderWidth = 2;
        break;
      case OptionState.correct:
        borderColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        textColor = const Color(0xFF065F46);
        labelBg = const Color(0xFF10B981);
        labelText = Colors.white;
        trailingIcon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF10B981);
        borderWidth = 2;
        break;
      case OptionState.wrong:
        borderColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFF991B1B);
        labelBg = const Color(0xFFEF4444);
        labelText = Colors.white;
        trailingIcon = Icons.cancel_rounded;
        iconColor = const Color(0xFFEF4444);
        borderWidth = 2;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 52), // Meets tap target 48dp+
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: state == OptionState.correct
              ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))]
              : state == OptionState.wrong
                  ? [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3))]
                  : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 13.0),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: labelBg,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: labelText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: state != OptionState.idle ? FontWeight.w600 : FontWeight.w400,
                        color: textColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, color: iconColor, size: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
