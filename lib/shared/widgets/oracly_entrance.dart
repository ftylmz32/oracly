/// EPIC-014 / EPIC-025 — Shared calm entrance animations for premium surfaces.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/immersive/immersive_motion.dart';
import '../../core/design_system/micro_details/micro_detail_tokens.dart';
import '../../core/theme/oracly_reduced_motion.dart';

/// How content arrives on screen — always subtle, never flashy.
enum OraclyEntranceMode {
  fade,
  fadeUp,
  softScale,
}

/// Single-element fade / slide / scale entrance aligned with immersive motion.
class OraclyEntrance extends StatefulWidget {
  const OraclyEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.mode = OraclyEntranceMode.fadeUp,
    this.offset = ImmersiveMotion.sectionEnterOffsetPx,
    this.curve = ImmersiveMotion.pageEnterCurve,
    this.duration = ImmersiveMotion.sectionEnter,
  });

  /// Staggered list item — delay grows linearly with [index].
  factory OraclyEntrance.staggered({
    Key? key,
    required Widget child,
    required int index,
    Duration baseDelay = Duration.zero,
    Duration step = MicroDetailTokens.listStaggerStep,
    OraclyEntranceMode mode = OraclyEntranceMode.fadeUp,
    double offset = ImmersiveMotion.sectionEnterOffsetPx,
    Duration duration = ImmersiveMotion.sectionEnter,
  }) {
    return OraclyEntrance(
      key: key,
      delay: baseDelay + (step * index),
      mode: mode,
      offset: offset,
      duration: duration,
      child: child,
    );
  }

  final Widget child;
  final Duration delay;
  final OraclyEntranceMode mode;
  final double offset;
  final Curve curve;
  final Duration duration;

  @override
  State<OraclyEntrance> createState() => _OraclyEntranceState();
}

class _OraclyEntranceState extends State<OraclyEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _shift;
  late final Animation<double> _scale;
  Timer? _delay;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _shift = Tween<double>(begin: widget.offset, end: 0).animate(curved);
    _scale = Tween<double>(
      begin: ImmersiveMotion.sectionEnterScaleBegin,
      end: 1,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (OraclyReducedMotion.of(context)) {
      _delay?.cancel();
      _controller.value = 1;
      _started = true;
      return;
    }
    if (_started) return;
    _started = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delay = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = _opacity.value;
        Widget body = child!;

        if (widget.mode == OraclyEntranceMode.softScale ||
            widget.mode == OraclyEntranceMode.fadeUp) {
          body = Transform.scale(
            scale: _scale.value,
            alignment: Alignment.topCenter,
            child: body,
          );
        }

        if (widget.mode == OraclyEntranceMode.fadeUp) {
          body = Transform.translate(
            offset: Offset(0, _shift.value),
            child: body,
          );
        }

        return Opacity(opacity: opacity, child: body);
      },
      child: widget.child,
    );
  }
}
