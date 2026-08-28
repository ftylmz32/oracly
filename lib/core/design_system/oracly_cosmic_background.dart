/// ORACLY — Canonical cosmic atmosphere for every screen.
///
/// Deep black-purple gradient, nebula, stars, gold dust, noise, vignette.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'oracly_light_sanctuary_background.dart';
import '../theme/oracly_quiet_motion.dart';

/// Unified premium background — Figma-accurate cosmic atmosphere.
class OraclyCosmicBackground extends StatefulWidget {
  const OraclyCosmicBackground({
    super.key,
    this.child,
    this.showStars = true,
    this.showNebula = true,
    this.showDust = true,
    this.showVignette = true,
    this.heroGlow = false,
  });

  final Widget? child;
  final bool showStars;
  final bool showNebula;
  final bool showDust;
  final bool showVignette;

  /// Extra gold radial glow for splash / hero moments.
  final bool heroGlow;

  @override
  State<OraclyCosmicBackground> createState() => _OraclyCosmicBackgroundState();
}

class _OraclyCosmicBackgroundState extends State<OraclyCosmicBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 48),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _motion, rest: 0);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return OraclyLightSanctuaryBackground(child: widget.child);
    }
    final still = OraclyQuietMotion.still(context);
    return AnimatedBuilder(
      animation: _motion,
      builder: (_, child) {
        final t = still ? 0.0 : _motion.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.cosmicDeep),
              child: SizedBox.expand(),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.28),
                      radius: 0.92,
                      colors: [
                        Color(0x242A1B5C),
                        Color(0x08C9A227),
                        Color(0x00000000),
                      ],
                      stops: [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.heroGlow)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.12),
                        radius: 0.78,
                        colors: [
                          AppColors.gold.withValues(alpha: 0.07),
                          AppColors.purpleGlow.withValues(alpha: 0.04),
                          AppColors.transparent,
                        ],
                        stops: const [0.0, 0.48, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.showNebula) ...[
              _Nebula(
                top: 48 + sin(t * pi * 2) * 6,
                left: -70,
                size: 260,
                color: AppColors.purpleDark.withValues(alpha: 0.22),
              ),
              _Nebula(
                top: 220 + cos(t * pi * 2) * 5,
                right: -90,
                size: 300,
                color: AppColors.purple.withValues(alpha: 0.16),
              ),
            ],
            if (widget.showStars || widget.showDust)
              RepaintBoundary(
                child: CustomPaint(
                  painter: _AtmospherePainter(
                    phase: t,
                    stars: widget.showStars,
                    dust: widget.showDust,
                    noise: !still,
                  ),
                  size: Size.infinite,
                ),
              ),
            if (widget.showVignette)
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.18),
                        radius: 1.22,
                        colors: [
                          Color(0x06C9A227),
                          Color(0x00000000),
                          Color(0x75000000),
                        ],
                        stops: [0.0, 0.48, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ?child,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Soft nebula — radial wash, never ImageFilter.blur (GPU-heavy on mid Android).
class _Nebula extends StatelessWidget {
  const _Nebula({
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: IgnorePointer(
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color,
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter({
    required this.phase,
    required this.stars,
    required this.dust,
    required this.noise,
  });

  final double phase;
  final bool stars;
  final bool dust;
  final bool noise;

  static const _stars = <(double x, double y, double r, double a)>[
    (0.08, 0.09, 0.28, 0.07),
    (0.22, 0.05, 0.24, 0.06),
    (0.48, 0.10, 0.26, 0.07),
    (0.78, 0.07, 0.24, 0.06),
    (0.16, 0.28, 0.22, 0.05),
    (0.62, 0.22, 0.24, 0.06),
    (0.88, 0.36, 0.22, 0.05),
    (0.34, 0.48, 0.20, 0.04),
  ];

  static const _dust = <(double x, double y)>[
    (0.10, 0.22),
    (0.24, 0.44),
    (0.40, 0.30),
    (0.58, 0.58),
    (0.76, 0.36),
    (0.90, 0.64),
    (0.34, 0.72),
    (0.62, 0.18),
  ];

  static final _noisePts = List<(double, double)>.generate(36, (i) {
    final rng = Random(42 + i);
    return (rng.nextDouble(), rng.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (stars) {
      for (var i = 0; i < _stars.length; i++) {
        final (x, y, r, a) = _stars[i];
        final tw = 0.55 + sin(phase * pi * 2 + i * 0.55) * 0.45;
        final useGold = i.isEven;
        canvas.drawCircle(
          Offset(size.width * x, size.height * y),
          r,
          Paint()
            ..color = (useGold ? AppColors.goldLight : Colors.white)
                .withValues(alpha: a * tw),
        );
      }
    }
    if (dust) {
      for (var i = 0; i < _dust.length; i++) {
        final (x, y) = _dust[i];
        final drift = sin(phase * pi * 2 + i) * 2.5;
        final alpha = 0.10 + sin(phase * pi * 2 + i * 0.7) * 0.05;
        canvas.drawCircle(
          Offset(size.width * x + drift, size.height * y),
          0.7,
          Paint()..color = AppColors.gold.withValues(alpha: alpha),
        );
      }
    }
    if (noise) {
      for (var i = 0; i < _noisePts.length; i++) {
        final (nx, ny) = _noisePts[i];
        final flicker = 0.5 + sin(phase * pi * 2 + i * 0.25) * 0.5;
        canvas.drawCircle(
          Offset(size.width * nx, size.height * ny),
          0.35,
          Paint()..color = Colors.white.withValues(alpha: 0.014 * flicker),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter old) =>
      old.phase != phase ||
      old.stars != stars ||
      old.dust != dust ||
      old.noise != noise;
}

/// Midnight + violet + antique-gold veil — one chamber language.
class OraclyChamberVeil extends StatelessWidget {
  const OraclyChamberVeil({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.12),
                radius: 0.96,
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
                center: const Alignment(0, -0.04),
                radius: 0.60,
                colors: [
                  AppColors.gold.withValues(alpha: 0.038),
                  AppColors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
