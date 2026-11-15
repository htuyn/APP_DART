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
    Color borderColor = Colors.grey.shade300;
    Color bgColor = Colors.transparent;
    Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    IconData? trailingIcon;
    Color iconColor = Colors.transparent;

    switch (state) {
      case OptionState.selected:
        borderColor = Theme.of(context).colorScheme.primary;
        bgColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
        break;
      case OptionState.correct:
        borderColor = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
        trailingIcon = Icons.check_circle_rounded;
        iconColor = Colors.green.shade700;
        break;
      case OptionState.wrong:
        borderColor = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        trailingIcon = Icons.cancel_rounded;
        iconColor = Colors.red.shade700;
        break;
      case OptionState.idle:
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48), // Tap target 48dp minimum
        child: Material(
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor, width: state == OptionState.idle ? 1 : 1.8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state == OptionState.selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade200,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: state == OptionState.selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: state != OptionState.idle ? FontWeight.w600 : FontWeight.normal,
                        color: textColor,
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
