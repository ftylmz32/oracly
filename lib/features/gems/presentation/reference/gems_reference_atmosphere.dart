/// Gems chamber shell — velvet depth, soft gem glow, never a sky shop.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';

class GemsReferenceAtmosphere extends StatelessWidget {
  const GemsReferenceAtmosphere({super.key, required this.child});

  final Widget child;

  static const _ink = Color(0xFF07040F);
  static const _velvet = Color(0xFF2A0E28);
  static const _candle = Color(0xFFD4A86A);

  @override
  Widget build(BuildContext context) {
    return OraclyCosmicBackground(
      heroGlow: false,
      showStars: false,
      showDust: false,
      showNebula: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.12),
                  radius: 0.98,
                  colors: [
                    OraclyChrome.violet.withValues(alpha: 0.22),
                    _velvet.withValues(alpha: 0.28),
                    _ink.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.08, -0.05),
                  radius: 0.52,
                  colors: [
                    _candle.withValues(alpha: 0.055),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
