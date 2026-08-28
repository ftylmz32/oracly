/// Reference home atmosphere — delegates to canonical cosmic background.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/oracly_cosmic_background.dart';

class HomeReferenceBackground extends StatelessWidget {
  const HomeReferenceBackground({
    super.key,
    required this.child,
    this.homeAtmosphere = false,
  });

  final Widget child;

  /// Extra violet radial — Home page only (other screens keep base cosmic).
  final bool homeAtmosphere;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    if (light || !homeAtmosphere) {
      return OraclyCosmicBackground(
        showDust: !homeAtmosphere,
        child: child,
      );
    }
    // One cosmic stack only — atmosphere radial lives inside the same tree.
    return OraclyCosmicBackground(
      showDust: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.05),
                  radius: 1.05,
                  colors: [
                    Color(0x3D2A1B5C),
                    Color(0x1A0C0820),
                    Color(0x00000000),
                  ],
                  stops: [0.0, 0.48, 1.0],
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
