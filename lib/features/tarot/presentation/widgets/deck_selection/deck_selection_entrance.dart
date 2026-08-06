/// OR-1020 — Sequential fade entrance for deck selection.
library;

import 'package:flutter/material.dart';

class DeckSelectionEntrance extends StatefulWidget {
  const DeckSelectionEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<DeckSelectionEntrance> createState() => _DeckSelectionEntranceState();
}

class _DeckSelectionEntranceState extends State<DeckSelectionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curved);

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
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

abstract final class DeckSelectionStagger {
  DeckSelectionStagger._();

  static const Duration header = Duration.zero;
  static const Duration orb = Duration(milliseconds: 100);
  static const _jitter = [13, 37, 59, 23, 71, 41];

  static Duration deck(int index) => Duration(
        milliseconds: 180 + index * 90 + _jitter[index % _jitter.length],
      );
}
