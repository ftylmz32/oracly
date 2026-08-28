/// Home hero plate — extremely subtle image drift + soft parallax.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/oracly_quiet_motion.dart';

/// Full-bleed hero artwork. Text stays outside this widget (static).
class DailyRitualHeroPlate extends StatefulWidget {
  const DailyRitualHeroPlate({
    super.key,
    required this.width,
    required this.height,
    required this.fallbackArt,
    this.assetPath = AppAssets.homeDream,
  });

  final double width;
  final double height;
  final double fallbackArt;
  /// Bugünün İzi uses dream-window art — never the hero oracle plate.
  final String assetPath;

  @override
  State<DailyRitualHeroPlate> createState() => _DailyRitualHeroPlateState();
}

class _DailyRitualHeroPlateState extends State<DailyRitualHeroPlate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, _drift, reverse: true, rest: 0.5);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final still = OraclyQuietMotion.still(context);
    final cacheW = (widget.width * dpr).round().clamp(1, 1600);
    final quality =
        still ? FilterQuality.medium : FilterQuality.high;

    return ColoredBox(
      color: const Color(0xFF0A0614),
      child: still
          ? _HeroImage(
              width: widget.width,
              height: widget.height,
              cacheWidth: cacheW,
              quality: quality,
              fallbackArt: widget.fallbackArt,
              assetPath: widget.assetPath,
            )
          : AnimatedBuilder(
              animation: _drift,
              builder: (context, child) {
                final t = _drift.value;
                // ~2.5px peak drift — felt, not noticed.
                final dx = math.sin(t * math.pi * 2) * 2.4;
                final dy = math.cos(t * math.pi * 2) * 1.6;
                // Opposite parallax on alignment (sky vs subject).
                final ax = 0.38 + math.sin(t * math.pi * 2) * 0.018;
                final ay = -0.12 + math.cos(t * math.pi * 2) * 0.012;
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.scale(
                    scale: 1.045,
                    alignment: Alignment.center,
                    filterQuality: quality,
                    child: _HeroImage(
                      width: widget.width,
                      height: widget.height,
                      cacheWidth: cacheW,
                      quality: quality,
                      fallbackArt: widget.fallbackArt,
                      assetPath: widget.assetPath,
                      alignment: Alignment(ax, ay),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.width,
    required this.height,
    required this.cacheWidth,
    required this.quality,
    required this.fallbackArt,
    required this.assetPath,
    this.alignment = const Alignment(0.55, -0.08),
  });

  final double width;
  final double height;
  final int cacheWidth;
  final FilterQuality quality;
  final double fallbackArt;
  final String assetPath;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      alignment: alignment,
      width: width,
      height: height,
      filterQuality: quality,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.nightlight_round,
          size: fallbackArt * 0.55,
          color: AppColors.goldLight.withValues(alpha: 0.72),
        );
      },
    );
  }
}
