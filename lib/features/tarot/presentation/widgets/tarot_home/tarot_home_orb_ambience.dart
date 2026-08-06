/// OR-400 / OR-406 — Sacred halo and ambient energy around the home orb.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../components/tarot_crystal_orb.dart';
import '../../../theme/tarot_tokens.dart';
import 'oracly_sacred_identity.dart';

/// Orb centerpiece — the visual king; ambience stays quiet.
class TarotHomeOrbAmbience extends StatefulWidget {
  const TarotHomeOrbAmbience({
    super.key,
    this.size = TarotTokens.homeOrbSize,
  });

  final double size;

  @override
  State<TarotHomeOrbAmbience> createState() => _TarotHomeOrbAmbienceState();
}

class _TarotHomeOrbAmbienceState extends State<TarotHomeOrbAmbience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: OraclyMotion.orbBreath,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extent = widget.size * 1.58;

    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_breath.value);
        final pulse = 0.96 + t * 0.04;

        return SizedBox(
          width: extent,
          height: extent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: pulse,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: OraclyMaterials.blurOrbFloor * 1.1,
                    sigmaY: OraclyMaterials.blurOrbFloor * 1.1,
                  ),
                  child: Container(
                    width: widget.size * 1.08,
                    height: widget.size * 0.32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: RadialGradient(
                        colors: [
                          OraclySacredPalette.purpleEnergy
                              .withValues(alpha: 0.10),
                          OraclySacredPalette.champagne.withValues(alpha: 0.04),
                          AppColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              CustomPaint(
                size: Size(extent, extent),
                painter: _OrbHaloPainter(phase: t),
              ),
              TarotCrystalOrb(size: widget.size),
            ],
          ),
        );
      },
    );
  }
}

class _OrbHaloPainter extends CustomPainter {
  const _OrbHaloPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.38;

    canvas.drawCircle(
      center,
      r * (1.04 + phase * 0.02),
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
        ..color = OraclySacredPalette.champagne.withValues(alpha: 0.04 + phase * 0.02),
    );

    canvas.drawCircle(
      center,
      r * 1.12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..color = OraclySacredPalette.purpleEnergySoft
            .withValues(alpha: 0.05 + phase * 0.02),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbHaloPainter old) => old.phase != phase;
}
