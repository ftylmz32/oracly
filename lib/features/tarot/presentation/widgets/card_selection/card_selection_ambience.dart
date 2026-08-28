/// OR-1040 — Golden particles and purple fog around the card arc.
library;

import 'dart:math' show cos, pi, sin;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../../../core/theme/oracly_soft_glow.dart';
import '../../../motion/tarot_ambient_sync.dart';
import '../../../motion/tarot_cinematic_motion.dart';
import 'card_selection_candle.dart';
import 'sacred_moment.dart';

class CardSelectionAmbience extends StatefulWidget {
  const CardSelectionAmbience({
    super.key,
    this.sacred = 0,
    this.sacredLinear = 0,
  });

  final double sacred;
  final double sacredLinear;

  @override
  State<CardSelectionAmbience> createState() => _CardSelectionAmbienceState();
}

class _CardSelectionAmbienceState extends State<CardSelectionAmbience>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion = AnimationController(
      vsync: this,
      duration: TarotCinematicMotion.ambient,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tarotSyncAmbient(context, _motion);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    tarotSyncAmbient(context, _motion);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, _) {
        final t = _motion.value;
        final gather = SacredMoment.orbGather(widget.sacredLinear);
        final breath = SacredMoment.breathHold(widget.sacredLinear);
        final driftScale = 1 - gather * 0.88;
        final breathMotion = 0.5 + sin(t * pi * 2) * 0.5 * driftScale * (1 - breath * 0.65);
        return IgnorePointer(
          child: RepaintBoundary(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CardSelectionCandle(
                  phase: t * pi * 2,
                  gather: gather,
                  breathMotion: breathMotion,
                ),
                Transform.translate(
                  offset: Offset(
                    sin(t * pi * 2) * 8 * driftScale,
                    12 + cos(t * pi * 2) * 5 * driftScale,
                  ),
                  child: OraclySoftGlow(
                    width: 260 + breathMotion * 14 - gather * 48,
                    height: 160 + breathMotion * 10 - gather * 36,
                    sigma: 56,
                    color: OraclySignaturePalette.purpleEnergySoft.withValues(
                      alpha: (OraclySignatureMaterials.particleAlpha * 3 +
                              breathMotion * 0.05) *
                          (1 - gather * 0.55),
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(340, 220),
                  painter: _RitualOrbGatherPainter(
                    gather: gather,
                    breath: breath,
                  ),
                ),
                CustomPaint(
                  size: const Size(340, 220),
                  painter: _BreathingGlowPainter(
                    intensity: (0.50 + breathMotion * 0.20) * (1 - gather * 0.30) +
                        gather * 0.26,
                    focus: gather,
                  ),
                ),
                if (gather < 0.90)
                  CustomPaint(
                    size: const Size(340, 220),
                    painter: _GoldDustPainter(
                      phase: t * pi * 2 * driftScale,
                      intensity: (1 - gather * 0.82) * (1 - breath * 0.4),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ritual orb — light gathers inward before knowledge arrives.
class _RitualOrbGatherPainter extends CustomPainter {
  const _RitualOrbGatherPainter({
    required this.gather,
    required this.breath,
  });

  final double gather;
  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    if (gather <= 0.02) return;

    final center = Offset(size.width / 2, size.height * 0.38);
    final hold = 1 - breath * 0.35;
    final innerR = size.width * lerpDouble(0.14, 0.10, gather)! * hold;
    final outerR = size.width * lerpDouble(0.22, 0.16, gather)! * hold;

    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            OraclySignaturePalette.champagne.withValues(alpha: 0.10 * gather),
            OraclySignaturePalette.purpleGlow(0.06 * gather),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: innerR)),
    );

    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45
        ..color = AppColors.goldLight.withValues(alpha: 0.08 * gather * hold),
    );
  }

  @override
  bool shouldRepaint(covariant _RitualOrbGatherPainter oldDelegate) {
    return oldDelegate.gather != gather || oldDelegate.breath != breath;
  }
}

class _BreathingGlowPainter extends CustomPainter {
  const _BreathingGlowPainter({
    required this.intensity,
    this.focus = 0,
  });

  final double intensity;
  final double focus;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final radius = size.width * lerpDouble(0.38, 0.30, focus.clamp(0.0, 1.0))!;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.purpleGlow.withValues(alpha: 0.20 * intensity + focus * 0.06),
            OraclySignaturePalette.champagne.withValues(
              alpha: OraclySignatureMaterials.particleAlpha * intensity +
                  focus * 0.03 +
                  0.04 * intensity,
            ),
            AppColors.transparent,
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _BreathingGlowPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.focus != focus;
  }
}

class _GoldDustPainter extends CustomPainter {
  const _GoldDustPainter({
    required this.phase,
    this.intensity = 1,
  });

  final double phase;
  final double intensity;

  static const _specks = <(double x, double y, double r, double speed)>[
    (-0.38, -0.10, 1.0, 0.8),
    (-0.22, 0.14, 0.8, 1.1),
    (-0.06, -0.18, 1.1, 0.9),
    (0.10, 0.08, 0.9, 1.2),
    (0.24, -0.12, 1.0, 0.75),
    (0.36, 0.10, 0.8, 1.0),
    (-0.30, 0.20, 0.9, 0.65),
    (0.18, 0.22, 0.85, 0.95),
    (-0.14, -0.24, 1.0, 1.05),
    (0.32, -0.20, 0.75, 0.85),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.52;
    for (var i = 0; i < _specks.length; i++) {
      final (nx, ny, r, speed) = _specks[i];
      final drift = sin(phase * speed + i) * 4;
      final lift = cos(phase * speed * 0.8 + i) * 3;
      final tw = 0.45 + sin(phase * 1.3 + i) * 0.3;
      canvas.drawCircle(
        Offset(cx + nx * size.width * 0.44 + drift, cy + ny * size.height * 0.38 + lift),
        r,
        Paint()..color = OraclySignaturePalette.champagne.withValues(
          alpha: OraclySignatureMaterials.particleAlpha * 3.3 * tw * intensity,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldDustPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.intensity != intensity;
  }
}
