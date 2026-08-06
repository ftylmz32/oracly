/// OR-1010 / OR-409 — Hero-first entrance; scroll handles other chambers.
library;

import 'package:flutter/material.dart';

import 'oracly_sacred_identity.dart';

/// Fade + slide reveal — reserved for the Hero chamber only.
class TarotHomeEntrance extends StatefulWidget {
  const TarotHomeEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.hero = false,
  });

  final Widget child;
  final Duration delay;

  /// Hero orb leads — slower, more deliberate reveal.
  final bool hero;

  @override
  State<TarotHomeEntrance> createState() => _TarotHomeEntranceState();
}

class _TarotHomeEntranceState extends State<TarotHomeEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.hero
          ? const Duration(milliseconds: 1400)
          : OraclyMotion.entrance,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.hero ? Curves.easeOutQuart : OraclyMotion.curve,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.hero ? 0.012 : OraclyMotion.entranceSlide),
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(
      begin: widget.hero ? 0.985 : OraclyMotion.entranceScaleBegin,
      end: 1,
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
        child: ScaleTransition(
          scale: _scale,
          alignment: Alignment.topCenter,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Standard stagger delays — hero only; scroll discovery handles the rest.
abstract final class TarotHomeStagger {
  TarotHomeStagger._();

  static const Duration hero = OraclyMotion.staggerHero;
}
