/// Quiet Günün Mesajı chamber — small celestial hush, never a spectacle.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';

class DailyMessageAtmosphere extends StatelessWidget {
  const DailyMessageAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return OraclyCosmicBackground(child: OraclyChamberVeil(child: child));
    }
    return OraclyCosmicBackground(
      heroGlow: false,
      showStars: true,
      showNebula: false,
      showDust: true,
      child: OraclyChamberVeil(
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.62),
                    radius: 0.55,
                    colors: [
                      OraclyChrome.gold.withValues(alpha: 0.08),
                      OraclyChrome.violet.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.42, 1.0],
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
