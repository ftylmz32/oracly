/// The user's cup is the reading surface — full evidence, never hard-cropped.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/performance/oracly_decode_cache.dart';
import '../../../../shared/camera/guides/coffee_cup_ring_painter.dart';
import 'coffee_cup_frame.dart';
import 'coffee_reference_tokens.dart';

class CoffeeGoldPreview extends StatelessWidget {
  const CoffeeGoldPreview({
    super.key,
    required this.path,
    this.contain = false,
    this.framed = false,
    this.attention = false,
    this.hero = false,
  });

  final String path;
  final bool contain;
  final bool framed;
  final bool attention;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final surface = RepaintBoundary(
      child: ColoredBox(
        color: CoffeeReferenceTokens.cupWell,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: contain ? BoxFit.contain : BoxFit.cover,
              alignment: Alignment.center,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              cacheWidth: oraclyDecodeCachePx(hero ? 720 : 560, dpr),
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.coffee_outlined,
                  color: OraclyChrome.goldLight.withValues(alpha: 0.42),
                  size: 48,
                );
              },
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.12),
                    radius: 1.1,
                    colors: [
                      CoffeeReferenceTokens.amberGlow.withValues(
                        alpha: attention ? 0.16 : 0.10,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            if (framed)
              IgnorePointer(
                child: CustomPaint(
                  painter: CoffeeCupRingPainter(
                    pulse: attention ? 0.85 : 0.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (!framed && !hero) return surface;
    return CoffeeCupFrame(
      hero: hero,
      attention: attention,
      child: surface,
    );
  }
}
