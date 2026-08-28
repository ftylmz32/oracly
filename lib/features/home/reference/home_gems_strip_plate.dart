/// Home gems strip plate - luminous gem art with quiet physical motion.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_gem_facet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/oracly_quiet_motion.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import 'home_gems_strip_sparks.dart';

class HomeGemsStripPlate extends StatefulWidget {
  const HomeGemsStripPlate({super.key});

  @override
  State<HomeGemsStripPlate> createState() => _HomeGemsStripPlateState();
}

class _HomeGemsStripPlateState extends State<HomeGemsStripPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _breath, reverse: true, rest: 0.42);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = OraclyQuietMotion.still(context);
    return Align(
      alignment: Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.58,
        heightFactor: 1,
        child: still
            ? const _PlateLayers(t: 0.42)
            : AnimatedBuilder(
                animation: _breath,
                builder: (context, _) => _PlateLayers(t: _breath.value),
              ),
      ),
    );
  }
}

class _PlateLayers extends StatelessWidget {
  const _PlateLayers({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(t * math.pi * 2);
    final dx = wave * 0.9;
    final dy = math.cos(t * math.pi * 2) * 0.65;
    final shear = 0.08 + wave * 0.03;
    final spark = 0.06 + (wave.abs() * 0.045);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.35, 0.1),
              radius: 0.95,
              colors: [
                AppColors.glowPurple.withValues(alpha: 0.18 + spark * 0.22),
                AppColors.glowGold.withValues(alpha: 0.08 + spark * 0.10),
                Colors.transparent,
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: 1.02,
            alignment: Alignment.centerRight,
            filterQuality: FilterQuality.medium,
            child: Opacity(
              opacity: 0.96,
              child: OraclyAssetImage(
                assetPath: AppAssets.homeGemsBanner,
                fit: BoxFit.cover,
                alignment: Alignment(0.12 + wave * 0.012, wave * 0.01),
                filterQuality: FilterQuality.medium,
                cacheCapPx: 640,
                fallback: const Center(
                  child: OraclyGemFacet(size: 28, glow: 0.8),
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Transform.translate(
            offset: Offset(shear * 18, 0),
            child: Opacity(
              opacity: 0.10 + spark * 0.32,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.9, -0.6),
                    end: Alignment(0.7, 0.8),
                    colors: [
                      Color(0x00FFFFFF),
                      Color(0x22FFF6E0),
                      Color(0x18E8C872),
                      Color(0x00FFFFFF),
                    ],
                    stops: [0.18, 0.44, 0.52, 0.78],
                  ),
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: HomeGemsStripSparksPainter(phase: t, intensity: spark),
          ),
        ),
      ],
    );
  }
}
