import 'dart:math';

import 'package:flutter/material.dart';

import '../copy/tarot_l10n.dart';
import '../models/tarot_card.dart';
import '../motion/tarot_cinematic_motion.dart';
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
      duration: TarotCinematicMotion.flip + TarotCinematicMotion.preFlip,
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
        final t = TarotCinematicMotion.curve(
          TarotCinematicMotion.weight,
          _controller.value,
        );
        final lift = TarotCinematicMotion.curve(
          TarotCinematicMotion.lift,
          (t / 0.40).clamp(0.0, 1.0),
        );
        final flipT = ((t - 0.32) / 0.58).clamp(0.0, 1.0);
        final angle = TarotCinematicMotion.curve(
              TarotCinematicMotion.settle,
              flipT,
            ) *
            pi;
        final front = angle >= pi / 2;

        return Transform.translate(
          offset: Offset(0, -18 * lift),
          child: Transform.scale(
            scale: 1 + (0.018 * lift),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.00115)
                ..rotateY(angle),
              child: front
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: TarotCardFace(
                        label: TarotL10n.cardNameOf(widget.card),
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
      offset: const Offset(0, -18),
      child: Transform.scale(
        scale: 1.02,
        child: TarotCardFace(
          label: TarotL10n.cardNameOf(card),
          image: card.image,
          width: width,
          height: height,
          radius: radius,
        ),
      ),
    );
  }
}
