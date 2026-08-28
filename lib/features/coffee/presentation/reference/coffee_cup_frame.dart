/// Shared gold frame for the real cup — capture, wait, and result.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import 'coffee_reference_tokens.dart';

class CoffeeCupFrame extends StatelessWidget {
  const CoffeeCupFrame({
    super.key,
    required this.child,
    this.hero = false,
    this.attention = false,
  });

  final Widget child;
  final bool hero;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final goldA = attention ? 0.40 : (hero ? 0.30 : 0.26);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: CoffeeReferenceTokens.heroRadius,
        boxShadow: CoffeeReferenceTokens.cupFrameShadows(hero: hero),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: CoffeeReferenceTokens.heroRadius,
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: goldA),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: CoffeeReferenceTokens.heroRadius,
          child: child,
        ),
      ),
    );
  }
}
