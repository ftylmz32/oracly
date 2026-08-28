import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

typedef DeckShuffleCardBuilder = Widget Function(
  BuildContext context,
  int index,
  Widget card,
);

class DeckShuffleAnimation extends StatefulWidget {
  const DeckShuffleAnimation({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 1000),
    this.cardCount = 8,
    this.cardBuilder,
  });

  final VoidCallback onComplete;
  final Duration duration;
  final int cardCount;
  final DeckShuffleCardBuilder? cardBuilder;

  @override
  State<DeckShuffleAnimation> createState() => _DeckShuffleAnimationState();
}

class _DeckShuffleAnimationState extends State<DeckShuffleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _envelope(double t) => sin(t * pi);

  Offset _offsetFor(int index, double t) {
    final e = _envelope(t);
    return Offset(
      sin((index + 1) * 1.4 + t * pi * 2) * 18 * e + index * 3.0 * (1 - t),
      cos((index + 1) * 1.1 + t * pi * 2) * 12 * e - index * 2.5 * (1 - t),
    );
  }

  double _rotationFor(int index, double t) {
    final e = _envelope(t);
    final base = (index - (widget.cardCount - 1) / 2) * 0.04;
    return (base + sin(t * pi * 2 + index * 0.9) * 0.08) * e;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(
          _controller.value.clamp(0.0, 1.0),
        );
        final glow = 0.12 + sin(t * pi * 3) * 0.06;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 140,
              height: 220,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryLight.withValues(alpha: glow),
                    blurRadius: 42,
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: glow * 0.6),
                    blurRadius: 28,
                  ),
                ],
              ),
            ),
            for (var i = 0; i < widget.cardCount; i++)
              Transform.translate(
                offset: _offsetFor(i, t),
                child: Transform.rotate(
                  angle: _rotationFor(i, t),
                  child: widget.cardBuilder?.call(context, i, const SizedBox()) ??
                      const SizedBox(),
                ),
              ),
          ],
        );
      },
    );
  }
}
