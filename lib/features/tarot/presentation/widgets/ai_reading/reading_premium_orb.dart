/// OR-301 — Large sacred OR orb with breathing glow and particles.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class ReadingPremiumOrb extends StatefulWidget {
  const ReadingPremiumOrb({
    super.key,
    this.size = 88,
  });

  final double size;

  @override
  State<ReadingPremiumOrb> createState() => _ReadingPremiumOrbState();
}

class _ReadingPremiumOrbState extends State<ReadingPremiumOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) {
          final t = _breath.value;
          final glow = 0.45 + sin(t * pi) * 0.35;
          final scale = 1.0 + sin(t * pi) * 0.025;

          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size + 48,
              height: widget.size + 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(5, (i) {
                    final angle = t * pi * 2 + i * 1.25;
                    final radius = widget.size * 0.38 + sin(angle) * 4;
                    return Transform.translate(
                      offset: Offset(
                        cosApprox(angle) * radius,
                        sinApprox(angle) * radius,
                      ),
                      child: Container(
                        width: 3 + i * 0.4,
                        height: 3 + i * 0.4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldLight.withValues(
                            alpha: 0.25 + glow * 0.35,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.goldGlow.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  Container(
                    width: widget.size + 20,
                    height: widget.size + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purpleGlow
                              .withValues(alpha: 0.35 + glow * 0.3),
                          blurRadius: 32 + glow * 16,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: AppColors.goldGlow
                              .withValues(alpha: 0.28 + glow * 0.22),
                          blurRadius: 20 + glow * 10,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.goldLight.withValues(alpha: 0.92),
                          AppColors.purple.withValues(alpha: 0.78),
                          AppColors.purpleDark,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: 0.55),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: widget.size * 0.28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double cosApprox(double x) => sin(x + pi / 2);
  double sinApprox(double x) => sin(x);
}
