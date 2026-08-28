/// Cinematic photo reveal — gold oval, midnight bloom. Never fake overlays.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../performance/oracly_decode_cache.dart';
import '../theme/app_colors.dart';
import 'chamber_hero_stage.dart';
import 'oracly_chrome.dart';
import 'oracly_soft_reveal.dart';

class ChamberCinematicPhoto extends StatelessWidget {
  const ChamberCinematicPhoto({
    super.key,
    required this.path,
    this.warm = true,
    this.fit = BoxFit.cover,
    this.soft = false,
    this.overlay,
  });

  final String path;
  final bool warm;
  final BoxFit fit;

  /// Quieter gold edge for ritual prep / wait.
  final bool soft;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return OraclySoftReveal(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 280.0;
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final cacheW = oraclyDecodeCachePx(
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360,
            dpr,
          );
          return ChamberHeroStage(
            warm: warm,
            glow: soft ? 0.88 : 1.05,
            child: Center(child: _frame(h, cacheW)),
          );
        },
      ),
    );
  }

  Widget _frame(double h, int? cacheW) {
    final radius = soft ? 22.0 : 28.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: soft ? 0.28 : 0.62),
          width: soft ? 0.9 : 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.gold.withValues(alpha: soft ? 0.14 : 0.28),
            blurRadius: soft ? 16 : 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: double.infinity,
          height: h,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(path),
                fit: fit,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                cacheWidth: cacheW,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: AppColors.surface.withValues(alpha: 0.8),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: OraclyChrome.gold.withValues(alpha: 0.55),
                    ),
                  );
                },
              ),
              ?overlay,
            ],
          ),
        ),
      ),
    );
  }
}
