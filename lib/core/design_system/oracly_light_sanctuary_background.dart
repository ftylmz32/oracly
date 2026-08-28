/// Warm ivory sanctuary — Light appearance atmosphere (not Material white).
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Soft daylight plane for [Brightness.light] — calm ivory + gold wash.
class OraclyLightSanctuaryBackground extends StatelessWidget {
  const OraclyLightSanctuaryBackground({super.key, this.child});

  final Widget? child;

  static const LinearGradient _ivory = LinearGradient(
    begin: Alignment(-0.1, -1),
    end: Alignment(0.15, 1.05),
    colors: [
      Color(0xFFFBF6EE),
      Color(0xFFF7F1E8),
      Color(0xFFF0E6D8),
      Color(0xFFEDE4D4),
    ],
    stops: [0.0, 0.28, 0.72, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: _ivory),
          child: SizedBox.expand(),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 0.95,
                  colors: [
                    AppColors.light.gold.withValues(alpha: 0.10),
                    AppColors.light.purple.withValues(alpha: 0.04),
                    AppColors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}
