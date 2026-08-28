/// Kahve Falı chamber — warm ceremonial wash over midnight glass.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';
import 'coffee_reference_tokens.dart';

class CoffeeReferenceAtmosphere extends StatelessWidget {
  const CoffeeReferenceAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return OraclyCosmicBackground(child: OraclyChamberVeil(child: child));
    }
    return OraclyCosmicBackground(
      heroGlow: true,
      showDust: true,
      child: OraclyChamberVeil(
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.38),
                    radius: 1.12,
                    colors: [
                      CoffeeReferenceTokens.amberGlow.withValues(alpha: 0.14),
                      OraclyChrome.violet.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.44, 1.0],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
