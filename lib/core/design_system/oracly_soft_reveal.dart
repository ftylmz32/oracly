/// Calm fade + micro-lift reveal — no bounce. Honors reduced motion.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/oracly_reduced_motion.dart';
import 'app_motion.dart';

class OraclySoftReveal extends StatefulWidget {
  const OraclySoftReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotionDuration.normal,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<OraclySoftReveal> createState() => _OraclySoftRevealState();
}

class _OraclySoftRevealState extends State<OraclySoftReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _lift;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: AppMotionCurve.easeOut,
    );
    _fade = curve;
    _lift = Tween<Offset>(
      begin: const Offset(0, 0.018),
      end: Offset.zero,
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    if (OraclyReducedMotion.of(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _lift, child: widget.child),
    );
  }
}
