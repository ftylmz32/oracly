/// EPIC-031 — Tarot atmosphere — same celestial shell as Home, heroGlow on.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/oracly_cosmic_background.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../motion/tarot_cinematic_motion.dart';

class TarotEpic031Background extends StatefulWidget {
  const TarotEpic031Background({super.key, required this.child});

  final Widget child;

  @override
  State<TarotEpic031Background> createState() => _TarotEpic031BackgroundState();
}

class _TarotEpic031BackgroundState extends State<TarotEpic031Background>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: TarotCinematicMotion.chamber,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyReducedMotion.playOnce(context, _enter);
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final air = TarotCinematicMotion.unit(
          TarotCinematicMotion.weight.transform(
            (_enter.value / 0.28).clamp(0.0, 1.0),
          ),
        );
        return Opacity(opacity: air, child: child);
      },
      child: OraclyCosmicBackground(
        heroGlow: true,
        showDust: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.12),
                    radius: 0.95,
                    colors: [
                      Color(0x3D2A1B5C),
                      Color(0x180C0820),
                      Color(0x00000000),
                    ],
                    stops: [0.0, 0.48, 1.0],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.05),
                    radius: 0.7,
                    colors: [
                      AppColors.gold.withValues(alpha: 0.035),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}
