/// Soft vignette over the real cup — depth without hiding grounds.
library;

import 'package:flutter/material.dart';

import 'coffee_reference_tokens.dart';

class CoffeeResultPhotoVeil extends StatelessWidget {
  const CoffeeResultPhotoVeil({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = CoffeeReferenceTokens.veilInk;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.05),
          radius: 1.15,
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
              ink.withValues(alpha: 0.22),
            ],
            stops: const [0, 0.48, 1],
          ),
        ),
      ),
    );
  }
}
