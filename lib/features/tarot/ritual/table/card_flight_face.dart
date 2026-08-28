/// Back/face content for [CardFlightActor] — content changes, actor does not.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../presentation/widgets/card_reveal/card_reveal_spread.dart';
import '../widgets/ritual_card_shell.dart';

class CardFlightFace extends StatelessWidget {
  const CardFlightFace({
    super.key,
    required this.flipProgress,
    this.face,
  });

  final double flipProgress;
  final RevealCardData? face;

  @override
  Widget build(BuildContext context) {
    final angle = flipProgress.clamp(0.0, 1.0) * math.pi;
    final showFront = face != null && angle >= math.pi / 2;
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
                label: face!.displayName,
                image: face!.imageAsset,
                reversed: face!.isReversed,
              ),
            )
          : const RitualCardBack(),
    );
  }
}
