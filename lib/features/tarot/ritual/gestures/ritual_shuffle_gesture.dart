/// Physical swipe shuffle ? two meaningful motions complete once.
library;

import "package:flutter/material.dart";
import "package:flutter/services.dart";

/// Accumulates horizontal swipe energy without mutating domain state.
class RitualShuffleGesture extends StatefulWidget {
  const RitualShuffleGesture({
    super.key,
    required this.enabled,
    required this.onVisual,
    required this.onComplete,
    required this.child,
    this.requiredMotions = 2,
  });

  final bool enabled;
  final ValueChanged<double> onVisual;
  final VoidCallback onComplete;
  final Widget child;
  final int requiredMotions;

  @override
  State<RitualShuffleGesture> createState() => _RitualShuffleGestureState();
}

class _RitualShuffleGestureState extends State<RitualShuffleGesture> {
  double _accum = 0;
  int _motions = 0;
  bool _done = false;
  double _live = 0;

  void _endStroke() {
    if (_done || !widget.enabled) return;
    if (_accum.abs() < 90) {
      _accum = 0;
      widget.onVisual(0);
      return;
    }
    _motions += 1;
    _accum = 0;
    HapticFeedback.selectionClick();
    widget.onVisual((_motions / widget.requiredMotions).clamp(0.0, 1.0));
    if (_motions >= widget.requiredMotions) {
      _done = true;
      HapticFeedback.mediumImpact();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: widget.enabled && !_done
          ? (d) {
              _accum += d.delta.dx;
              _live = (_live + d.delta.dx * 0.01).clamp(-1.0, 1.0);
              widget.onVisual(
                (_motions / widget.requiredMotions + _live.abs() * 0.25)
                    .clamp(0.0, 0.95),
              );
            }
          : null,
      onHorizontalDragEnd: widget.enabled && !_done ? (_) => _endStroke() : null,
      child: widget.child,
    );
  }
}
