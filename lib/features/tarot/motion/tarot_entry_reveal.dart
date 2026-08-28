/// Layered chamber entrance — room appears, then the deck, then copy.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/oracly_reduced_motion.dart';
import 'tarot_cinematic_motion.dart';

class TarotEntryReveal extends StatefulWidget {
  const TarotEntryReveal({
    super.key,
    required this.title,
    required this.hero,
    required this.rest,
  });

  final Widget title;
  final Widget hero;
  final Widget rest;

  @override
  State<TarotEntryReveal> createState() => _TarotEntryRevealState();
}

class _TarotEntryRevealState extends State<TarotEntryReveal>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _master;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _master = AnimationController(
      vsync: this,
      duration: TarotCinematicMotion.chamber,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _master.stop();
    } else if (state == AppLifecycleState.resumed &&
        _master.value < 1 &&
        !OraclyReducedMotion.of(context)) {
      _master.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyReducedMotion.playOnce(context, _master);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _master.dispose();
    super.dispose();
  }

  double _span(double start, double end) {
    final t = _master.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return TarotCinematicMotion.weight.transform(
      ((t - start) / (end - start)).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _master,
      builder: (context, _) {
        final deck = _span(0.10, 0.46);
        final glint = _span(0.38, 0.62);
        final copy = _span(0.52, 0.92);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Opacity(opacity: TarotCinematicMotion.unit(copy), child: widget.title),
            Opacity(
              opacity: TarotCinematicMotion.unit(deck),
              child: Transform.translate(
                offset: Offset(0, (1 - TarotCinematicMotion.overshoot(deck)) * 14),
                child: _HeroProgress(glint: glint, child: widget.hero),
              ),
            ),
            Opacity(
              opacity: TarotCinematicMotion.unit(copy),
              child: Transform.translate(
                offset: Offset(0, (1 - copy) * 10),
                child: widget.rest,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroProgress extends InheritedWidget {
  const _HeroProgress({required this.glint, required super.child});

  final double glint;

  static double of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HeroProgress>()?.glint ??
        0;
  }

  @override
  bool updateShouldNotify(_HeroProgress oldWidget) => glint != oldWidget.glint;
}

double tarotEntryGlintOf(BuildContext context) => _HeroProgress.of(context);
