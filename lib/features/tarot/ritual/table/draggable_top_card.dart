/// Physics top-card drag — lift, 1:1 follow, tilt, spring snap-back, commit.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../gestures/ritual_draw_gesture.dart';
import '../widgets/ritual_card_shell.dart';

class DraggableTopCard extends StatefulWidget {
  const DraggableTopCard({
    super.key,
    required this.enabled,
    required this.onCommit,
    required this.onInteracted,
    this.onDragVisual,
  });

  final bool enabled;
  final Future<void> Function() onCommit;
  final VoidCallback onInteracted;
  final ValueChanged<double>? onDragVisual;

  @override
  State<DraggableTopCard> createState() => DraggableTopCardState();
}

class DraggableTopCardState extends State<DraggableTopCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring;
  Offset _drag = Offset.zero;
  bool _holding = false;
  bool _committed = false;
  bool _interacting = false;

  static const liftPx = 8.0;
  static const maxTiltRad = 8 * math.pi / 180;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        if (!_holding && !_committed) {
          setState(() => _drag = Offset(0, _spring.value));
          widget.onDragVisual?.call(
            (-_drag.dy / RitualDrawThreshold.commitPx).clamp(0.0, 1.2),
          );
        }
      });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _markInteracted() {
    if (_interacting) return;
    _interacting = true;
    widget.onInteracted();
  }

  void _snapBack() {
    final start = _drag.dy;
    _spring.value = start;
    final sim = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 180, damping: 16),
      start,
      0,
      0,
    );
    _spring.animateWith(sim).whenComplete(() {
      if (!mounted) return;
      setState(() => _drag = Offset.zero);
      widget.onDragVisual?.call(0);
    });
  }

  Future<void> _commit() async {
    if (_committed) return;
    _committed = true;
    HapticFeedback.mediumImpact();
    widget.onDragVisual?.call(1);
    await widget.onCommit();
  }

  @override
  Widget build(BuildContext context) {
    final lift = _holding || _drag.dy < -1 ? liftPx : 0.0;
    final dy = _drag.dy - lift;
    final tilt =
        (_drag.dx / 120).clamp(-1.0, 1.0) * maxTiltRad;
    final progress =
        (-_drag.dy / RitualDrawThreshold.commitPx).clamp(0.0, 1.2);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: widget.enabled && !_committed
          ? (d) {
              _markInteracted();
              _spring.stop();
              setState(() {
                _holding = true;
                _drag = Offset.zero;
              });
              HapticFeedback.selectionClick();
            }
          : null,
      onPanUpdate: widget.enabled && !_committed
          ? (d) {
              setState(() {
                _drag += d.delta;
                // Prefer upward extraction; clamp wild motion.
                _drag = Offset(
                  _drag.dx.clamp(-48.0, 48.0),
                  _drag.dy.clamp(-RitualDrawThreshold.commitPx * 1.4, 24.0),
                );
              });
              widget.onDragVisual?.call(progress);
            }
          : null,
      onPanEnd: widget.enabled && !_committed
          ? (_) async {
              setState(() => _holding = false);
              if (-_drag.dy >= RitualDrawThreshold.commitPx) {
                await _commit();
              } else {
                _snapBack();
              }
            }
          : null,
      onPanCancel: widget.enabled && !_committed
          ? () {
              setState(() => _holding = false);
              _snapBack();
            }
          : null,
      child: Transform.translate(
        offset: Offset(_drag.dx, dy),
        child: Transform.rotate(
          angle: tilt,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.35 + 0.25 * progress.clamp(0.0, 1.0),
                  ),
                  blurRadius: 18 + 16 * progress.clamp(0.0, 1.0),
                  offset: Offset(0, 8 + 10 * progress.clamp(0.0, 1.0)),
                ),
              ],
            ),
            child: const RitualCardBack(),
          ),
        ),
      ),
    );
  }
}
