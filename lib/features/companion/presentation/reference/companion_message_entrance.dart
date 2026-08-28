/// OR message appearance — quick fade/settle, reduced-motion safe.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';

enum CompanionMessageEntranceKind { user, assistant }

class CompanionMessageEntrance extends StatefulWidget {
  const CompanionMessageEntrance({
    super.key,
    required this.child,
    required this.kind,
    this.delay = Duration.zero,
  });

  final Widget child;
  final CompanionMessageEntranceKind kind;
  final Duration delay;

  @override
  State<CompanionMessageEntrance> createState() =>
      _CompanionMessageEntranceState();
}

class _CompanionMessageEntranceState extends State<CompanionMessageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final ms = widget.kind == CompanionMessageEntranceKind.user ? 160 : 200;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: CraftsmanshipRhythm.curve,
    );
    _opacity = curve;
    final lift = widget.kind == CompanionMessageEntranceKind.user ? 0.018 : 0.010;
    _slide = Tween<Offset>(
      begin: Offset(0, lift),
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
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
