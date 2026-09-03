/// OR-1010 / OR-408 — Deep sanctuary background for Tarot Home.
library;

import 'dart:math' show pi, sin;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';
import '../../../theme/tarot_tokens.dart';
import '../../../components/tarot_particle_layer.dart';
import '../tarot_home/oracly_sacred_identity.dart';
import 'tarot_atmosphere.dart';
import 'tarot_home_sanctuary_architecture.dart';

/// Layered celestial observatory — far nebula, mid architecture, near glints.
class TarotHomeBackground extends StatefulWidget {
  const TarotHomeBackground({super.key});

  @override
  State<TarotHomeBackground> createState() => _TarotHomeBackgroundState();
}

class _TarotHomeBackgroundState extends State<TarotHomeBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: TarotTokens.ambientLoop,
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final t = _drift.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            // —— Far layer: deep cosmic chamber ——
        const DecoratedBox(decoration: OraclySignatureChamber.cosmic),
            CustomPaint(
              painter: OraclyFarNebulaVeilPainter(phase: t),
              size: Size.infinite,
            ),
            _NebulaBlob(
              top: 120 + sin(t * pi * 2 + 1) * 4,
              right: -80,
              size: 240,
              color: OraclySacredPalette.deepViolet.withValues(alpha: 0.06),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.transparent,
                      AppColors.transparent,
                      OraclySacredPalette.obsidian.withValues(
                        alpha: TarotAtmosphere.backgroundVignette,
                      ),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
            ),
            const TarotParticleLayer(),
          ],
        );
      },
    );
  }
}

class _NebulaBlob extends StatelessWidget {
  const _NebulaBlob({
    this.top,
    this.right,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: OraclyMaterials.blurNebula,
            sigmaY: OraclyMaterials.blurNebula,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}
