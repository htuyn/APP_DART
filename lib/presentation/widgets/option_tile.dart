import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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

class _OptionTileState extends State<OptionTile>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _revealController;
  late Animation<double> _revealAnimation;
  OptionState _prevState = OptionState.idle;

  @override
  void initState() {
    super.initState();
    _prevState = widget.state;
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(OptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger reveal animation when transitioning to correct/wrong
    if (_prevState == OptionState.idle &&
        (widget.state == OptionState.correct ||
            widget.state == OptionState.wrong)) {
      _revealController.forward(from: 0);
      HapticFeedback.lightImpact();
    }
    _prevState = widget.state;
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    // ── Color tokens per state ──────────────────────────────────────────────
    Color borderColor;
    Color bgColor;
    Color textColor =
        theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black87);
    Color labelBg;
    Color labelText;
    IconData? trailingIcon;
    Color iconColor = Colors.transparent;
    double borderWidth;

    switch (widget.state) {
      case OptionState.idle:
        borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        labelBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        labelText = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
        borderWidth = 1.4;
        break;

      case OptionState.selected:
        borderColor = scheme.primary;
        bgColor = scheme.primary.withValues(alpha: isDark ? 0.15 : 0.08);
        labelBg = scheme.primary;
        labelText = Colors.white;
        borderWidth = 2.0;
        break;

      case OptionState.correct:
        borderColor = AppColors.success;
        bgColor = isDark
            ? AppColors.success.withValues(alpha: 0.18)
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
            ? AppColors.error.withValues(alpha: 0.18)
            : AppColors.errorLight;
        textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
        labelBg = AppColors.error;
        labelText = Colors.white;
        trailingIcon = Icons.cancel_rounded;
        iconColor = isDark ? const Color(0xFFFCA5A5) : AppColors.error;
        borderWidth = 2.0;
        break;
    }

    // Build shadow based on state
    List<BoxShadow> shadows;
    if (widget.state == OptionState.correct) {
      shadows = [
        BoxShadow(
          color: AppColors.success.withValues(alpha: isDark ? 0.3 : 0.2),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (widget.state == OptionState.wrong) {
      shadows = [
        BoxShadow(
          color: AppColors.error.withValues(alpha: isDark ? 0.28 : 0.18),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (widget.state == OptionState.selected) {
      shadows = [
        BoxShadow(
          color: scheme.primary.withValues(alpha: 0.15),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }

    Widget tileContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          // Label badge with animated transition
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
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
          // Option text
          Expanded(
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    widget.state != OptionState.idle ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
                height: 1.42,
              ),
            ),
          ),
          // Trailing icon with scale-in animation
          if (trailingIcon != null) ...[
            const SizedBox(width: 10),
            ScaleTransition(
              scale: _revealAnimation,
              child: Icon(trailingIcon, color: iconColor, size: 24),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.onTap != null) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (widget.onTap != null) {
            setState(() => _isPressed = false);
            widget.onTap!();
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.975 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 58),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: shadows,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  splashColor: borderColor.withValues(alpha: 0.1),
                  highlightColor: Colors.transparent,
                  onTap: widget.onTap,
                  child: tileContent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
