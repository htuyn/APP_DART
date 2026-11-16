import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum OptionState { idle, selected, correct, wrong }

class OptionTile extends StatefulWidget {
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
  State<OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<OptionTile> {
  bool _isHoveredOrPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color borderColor;
    Color bgColor;
    Color textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
    Color labelBg;
    Color labelText;
    IconData? trailingIcon;
    Color iconColor = Colors.transparent;
    double borderWidth = 1.4;

    switch (widget.state) {
      case OptionState.idle:
        borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        labelBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        labelText = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
        break;
      case OptionState.selected:
        borderColor = theme.colorScheme.primary;
        bgColor = theme.colorScheme.primary.withValues(alpha: 0.1);
        labelBg = theme.colorScheme.primary;
        labelText = Colors.white;
        borderWidth = 2.0;
        break;
      case OptionState.correct:
        borderColor = AppColors.success;
        bgColor = isDark
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.successLight;
        textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
        labelBg = AppColors.success;
        labelText = Colors.white;
        trailingIcon = Icons.check_circle_rounded;
        iconColor = isDark ? const Color(0xFF6EE7B7) : AppColors.success;
        borderWidth = 2.0;
        break;
      case OptionState.wrong:
        borderColor = AppColors.error;
        bgColor = isDark
            ? AppColors.error.withValues(alpha: 0.2)
            : AppColors.errorLight;
        textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
        labelBg = AppColors.error;
        labelText = Colors.white;
        trailingIcon = Icons.cancel_rounded;
        iconColor = isDark ? const Color(0xFFFCA5A5) : AppColors.error;
        borderWidth = 2.0;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: AnimatedScale(
        scale: _isHoveredOrPressed ? 0.99 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: widget.state == OptionState.correct
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : widget.state == OptionState.wrong
                    ? [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTapDown: (_) => setState(() => _isHoveredOrPressed = true),
              onTapCancel: () => setState(() => _isHoveredOrPressed = false),
              onTap: widget.onTap == null
                  ? null
                  : () {
                      setState(() => _isHoveredOrPressed = false);
                      widget.onTap!();
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: labelBg,
                      ),
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: labelText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: widget.state != OptionState.idle ? FontWeight.w700 : FontWeight.w500,
                          color: textColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 10),
                      Icon(trailingIcon, color: iconColor, size: 24),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
