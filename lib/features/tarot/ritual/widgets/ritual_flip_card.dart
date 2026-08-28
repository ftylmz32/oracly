/// Same visual card: back ? Y-axis flip ? face. No route reset.
library;

import "dart:math" as math;

import "package:flutter/material.dart";

import "ritual_card_shell.dart";

class RitualFlipCard extends StatelessWidget {
  const RitualFlipCard({
    super.key,
    required this.flipProgress,
    required this.label,
    required this.image,
    this.reversed = false,
    this.width,
    this.height,
  });

  final double flipProgress;
  final String label;
  final String image;
  final bool reversed;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final angle = flipProgress.clamp(0.0, 1.0) * math.pi;
    final showFront = angle >= math.pi / 2;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.00145)
        ..rotateY(angle),
      child: showFront
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: RitualCardFace(
                label: label,
                image: image,
                reversed: reversed,
                width: width,
                height: height,
              ),
            )
          : RitualCardBack(width: width, height: height),
    );
  }
}
