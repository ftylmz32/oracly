/// Drag top card upward past threshold to commit draw.
library;

import "package:flutter/material.dart";
import "package:flutter/services.dart";

abstract final class RitualDrawThreshold {
  RitualDrawThreshold._();

  /// Pixels of upward drag required to commit.
  static const commitPx = 96.0;
}

class RitualDrawGesture extends StatefulWidget {
  const RitualDrawGesture({
    super.key,
    required this.enabled,
    required this.onVisual,
    required this.onCommit,
    required this.child,
  });

  final bool enabled;
  final ValueChanged<double> onVisual;
  final VoidCallback onCommit;
  final Widget child;

  @override
  State<RitualDrawGesture> createState() => _RitualDrawGestureState();
}

class _RitualDrawGestureState extends State<RitualDrawGesture> {
  double _dy = 0;
  bool _locked = false;

  void _reset() {
    _dy = 0;
    widget.onVisual(0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: widget.enabled && !_locked
          ? (d) {
              // Upward is negative dy in Flutter.
              _dy = (_dy - d.delta.dy).clamp(0.0, RitualDrawThreshold.commitPx * 1.35);
              widget.onVisual(
                (_dy / RitualDrawThreshold.commitPx).clamp(0.0, 1.2),
              );
            }
          : null,
      onVerticalDragEnd: widget.enabled && !_locked
          ? (_) {
              if (_dy >= RitualDrawThreshold.commitPx) {
                _locked = true;
                HapticFeedback.mediumImpact();
                widget.onVisual(1);
                widget.onCommit();
              } else {
                _reset();
              }
            }
          : null,
      onVerticalDragCancel: widget.enabled && !_locked ? _reset : null,
      child: widget.child,
    );
  }
}
