import 'dart:math';

import 'package:flutter/material.dart';

import '../models/tarot_card.dart';
import '../widgets/tarot_card_shell.dart';

class CardDrawAnimation extends StatefulWidget {
  const CardDrawAnimation({
    super.key,
    required this.card,
    required this.onFlipComplete,
    this.width = 118,
    this.height = 198,
    this.radius = 28,
  });

  final TarotCard card;
  final VoidCallback onFlipComplete;
  final double width;
  final double height;
  final double radius;

  @override
  State<CardDrawAnimation> createState() => _CardDrawAnimationState();
}

class _CardDrawAnimationState extends State<CardDrawAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFlipComplete();
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        final lift = Curves.easeOutCubic.transform((t / 0.38).clamp(0.0, 1.0));
        final flipT = ((t - 0.35) / 0.55).clamp(0.0, 1.0);
        final angle = flipT * pi;
        final front = angle >= pi / 2;

        return Transform.translate(
          offset: Offset(0, -32 * lift),
          child: Transform.scale(
            scale: 1 + (0.03 * lift),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: front
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: TarotCardFace(
                        label: widget.card.name,
                        image: widget.card.image,
                        width: widget.width,
                        height: widget.height,
                        radius: widget.radius,
                      ),
                    )
                  : TarotCardBackFace(
                      width: widget.width,
                      height: widget.height,
                      radius: widget.radius,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class TarotRevealedCard extends StatelessWidget {
  const TarotRevealedCard({
    super.key,
    required this.card,
    this.width = 118,
    this.height = 198,
    this.radius = 28,
  });

  final TarotCard card;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -32),
      child: Transform.scale(
        scale: 1.08,
        child: TarotCardFace(
          label: card.name,
          image: card.image,
          width: width,
          height: height,
          radius: radius,
        ),
      ),
    );
  }
}
