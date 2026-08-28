/// Settled vignette over palm photos — shared depth, never analysis motion.
library;

import 'package:flutter/material.dart';

import 'palm_tokens.dart';

class PalmPhotoVeil extends StatelessWidget {
  const PalmPhotoVeil({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = PalmTokens.veilInk;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.06, -0.08),
          radius: 1.12,
          colors: [
            Colors.transparent,
            ink.withValues(alpha: 0.18),
          ],
          stops: const [0.55, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ink.withValues(alpha: 0.06),
              Colors.transparent,
              ink.withValues(alpha: 0.26),
            ],
            stops: const [0, 0.48, 1],
          ),
        ),
      ),
    );
  }
}
