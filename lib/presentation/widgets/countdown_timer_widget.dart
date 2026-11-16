import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatefulWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final bool prominent;

  const CountdownTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.prominent = false,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _wasCritical = false;

  bool get _isUrgent => widget.remainingSeconds <= 300 && widget.remainingSeconds > 0;
  bool get _isCritical => widget.remainingSeconds <= 60 && widget.remainingSeconds > 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_isCritical) {
      _pulseController.repeat(reverse: true);
      _wasCritical = true;
    }
  }

  @override
  void didUpdateWidget(CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCritical && !_wasCritical) {
      _pulseController.repeat(reverse: true);
      _wasCritical = true;
    } else if (!_isCritical && _wasCritical) {
      _pulseController.stop();
      _pulseController.value = 0;
      _wasCritical = false;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalSeconds > 0
        ? widget.remainingSeconds / widget.totalSeconds
        : 0.0;

    // Color transitions: primary → amber → red
    final Color color;
    if (_isCritical) {
      color = const Color(0xFFEF4444);
    } else if (_isUrgent) {
      color = const Color(0xFFF59E0B);
    } else {
      color = Theme.of(context).colorScheme.primary;
    }

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(
        horizontal: widget.prominent ? 14 : 10,
        vertical: widget.prominent ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: widget.prominent ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: _isCritical ? 0.6 : 0.3),
          width: _isCritical ? 1.8 : 1.2,
        ),
        boxShadow: _isCritical
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.prominent ? 22 : 16,
            height: widget.prominent ? 22 : 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: widget.prominent ? 2.8 : 2.2,
                color: color,
                backgroundColor: color.withValues(alpha: 0.16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isCritical)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                _formatDuration(widget.remainingSeconds),
                key: ValueKey(widget.remainingSeconds),
                style: TextStyle(
                  fontSize: widget.prominent ? 18 : 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            Text(
              _formatDuration(widget.remainingSeconds),
              style: TextStyle(
                fontSize: widget.prominent ? 18 : 14,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );

    if (_isCritical) {
      return ScaleTransition(scale: _pulseAnimation, child: container);
    }
    return container;
  }
}
