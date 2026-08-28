/// RC-002 / RC-007 — Gentle message appearance without layout jump.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';

class ConversationMessageEntrance extends StatefulWidget {
  const ConversationMessageEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<ConversationMessageEntrance> createState() =>
      _ConversationMessageEntranceState();
}

class _ConversationMessageEntranceState extends State<ConversationMessageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CraftsmanshipRhythm.appear,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: CraftsmanshipRhythm.curve,
    );
    _opacity = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.022),
      end: Offset.zero,
    ).animate(curve);
    _scale = Tween<double>(begin: 0.988, end: 1).animate(curve);

    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    if (OraclyReducedMotion.of(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xs),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
