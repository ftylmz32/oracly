/// Wider hero inset so the real cup leads the chamber.
library;

import 'package:flutter/material.dart';

import 'coffee_reference_tokens.dart';

class CoffeeResultHeroBleed extends StatelessWidget {
  const CoffeeResultHeroBleed({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final side = CoffeeReferenceTokens.screenHorizontal;
    return Transform.translate(
      offset: Offset(-side * 0.55, 0),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width - side * 0.9,
        child: child,
      ),
    );
  }
}
