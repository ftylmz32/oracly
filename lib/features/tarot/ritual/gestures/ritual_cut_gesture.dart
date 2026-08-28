/// Drag upper packet away, then recombine ? physical cut.
library;

import "package:flutter/material.dart";
import "package:flutter/services.dart";

class RitualCutGesture extends StatefulWidget {
  const RitualCutGesture({
    super.key,
    required this.enabled,
    required this.onVisual,
    required this.onComplete,
    required this.child,
  });

  final bool enabled;
  final void Function(double progress, bool separated) onVisual;
  final VoidCallback onComplete;
  final Widget child;

  @override
  State<RitualCutGesture> createState() => _RitualCutGestureState();
}

class _RitualCutGestureState extends State<RitualCutGesture> {
  bool _separated = false;
  bool _done = false;
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: widget.enabled && !_done
          ? (d) {
              _dx = (_dx + d.delta.dx).clamp(-160.0, 160.0);
              if (!_separated && _dx.abs() > 72) {
                _separated = true;
                HapticFeedback.selectionClick();
              }
              final p = (_dx.abs() / 140).clamp(0.0, 1.0);
              widget.onVisual(_separated ? p : p * 0.5, _separated);
            }
          : null,
      onHorizontalDragEnd: widget.enabled && !_done
          ? (_) {
              if (_separated && _dx.abs() < 48) {
                _done = true;
                HapticFeedback.mediumImpact();
                widget.onVisual(0, false);
                widget.onComplete();
                return;
              }
              if (!_separated) {
                _dx = 0;
                widget.onVisual(0, false);
              } else {
                // Keep separated; wait for recombine (drag back toward center).
                widget.onVisual((_dx.abs() / 140).clamp(0.0, 1.0), true);
              }
            }
          : null,
      child: widget.child,
    );
  }
}
