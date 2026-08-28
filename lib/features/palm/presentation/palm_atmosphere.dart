/// Intimate El Falı atmosphere — deeper than the shared cosmic veil.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/design_system/oracly_cosmic_background.dart';
import 'palm_tokens.dart';

class PalmAtmosphere extends StatelessWidget {
  const PalmAtmosphere({super.key, required this.child});

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
                    center: const Alignment(0, -0.16),
                    radius: 1.05,
                    colors: [
                      PalmTokens.amberGlow.withValues(alpha: 0.10),
                      OraclyChrome.violet.withValues(alpha: 0.18),
                      PalmTokens.veilInk.withValues(alpha: 0.34),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.28, 0.55, 1.0],
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
