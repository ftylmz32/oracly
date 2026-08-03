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
    this.duration = const Duration(milliseconds: 850),
    this.cardCount = 7,
    this.cardBuilder,
  });

  final VoidCallback onComplete;
  final Duration duration;
  final int cardCount;
  final DeckShuffleCardBuilder? cardBuilder;

  @override
  State<DeckShuffleAnimation> createState() =>
      _DeckShuffleAnimationState();
}

class _DeckShuffleAnimationState extends State<DeckShuffleAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _motionEnvelope(double t) => sin(t * pi);

  Offset _offsetFor(int index, double t) {
    final envelope = _motionEnvelope(t);
    final waveX = sin((index + 1) * 1.4 + t * pi * 2);
    final waveY = cos((index + 1) * 1.1 + t * pi * 2);
    final stackX = index * 3.0 * (1 - t);
    final stackY = -index * 2.0 * (1 - t);

    return Offset(
      waveX * 14 * envelope + stackX,
      waveY * 10 * envelope + stackY,
    );
  }

  double _rotationFor(int index, double t) {
    final envelope = _motionEnvelope(t);
    final base = (index - (widget.cardCount - 1) / 2) * 0.035;
    final wave = sin(t * pi * 2 + index * 0.9) * 0.07;
    return (base + wave) * envelope;
  }

  Widget _defaultCard() {
    return Container(
      width: 88,
      height: 152,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: .55),
          width: 1.2,
        ),
      ),
      child: Icon(
        Icons.auto_awesome,
        color: AppColors.gold.withValues(alpha: .75),
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        final glow = 0.14 + sin(t * pi * 3) * 0.08;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 110,
              height: 176,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: glow),
                    blurRadius: 34,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            for (var i = 0; i < widget.cardCount; i++)
              Transform.translate(
                offset: _offsetFor(i, t),
                child: Transform.rotate(
                  angle: _rotationFor(i, t),
                  child: widget.cardBuilder?.call(
                        context,
                        i,
                        _defaultCard(),
                      ) ??
                      _defaultCard(),
                ),
              ),
          ],
        );
      },
    );
  }
}
