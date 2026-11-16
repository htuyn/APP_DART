import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool prominent;

  const CountdownTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.prominent = false,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = remainingSeconds <= 300 && remainingSeconds > 0;
    final progress = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
    final color = isUrgent ? const Color(0xFFEF4444) : Theme.of(context).colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: prominent ? 14 : 10,
        vertical: prominent ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: prominent ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: prominent ? 22 : 16,
            height: prominent ? 22 : 16,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: prominent ? 2.8 : 2.2,
              color: color,
              backgroundColor: color.withValues(alpha: 0.16),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(remainingSeconds),
            style: TextStyle(
              fontSize: prominent ? 18 : 14,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
