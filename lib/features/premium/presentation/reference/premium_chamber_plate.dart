/// Photoreal exclusive chamber — astronomical globe, velvet, candlelight.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';

class PremiumChamberPlate extends StatelessWidget {
  const PremiumChamberPlate({super.key});

  /// Tall cinematic plate — reserved before decode; no layout jump.
  static const double aspectRatio = 4 / 5;

  static const _ink = Color(0xFF07040F);
  static const _candle = Color(0xFFD4A86A);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: OraclyChrome.heroRadius,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ColoredBox(
          color: _ink,
          child: Stack(
            fit: StackFit.expand,
            children: [
              OraclyAssetImage(
                assetPath: AppAssets.premiumChamberHero,
                fit: BoxFit.cover,
                // Keep globe + velvet sofa in the 4:5 band.
                alignment: const Alignment(0.0, -0.04),
                filterQuality: FilterQuality.high,
                fallback: const ColoredBox(color: _ink),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.42),
                      radius: 1.05,
                      colors: [
                        _candle.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.62],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.12),
                        Colors.transparent,
                        _ink.withValues(alpha: 0.28),
                        _ink.withValues(alpha: 0.78),
                      ],
                      stops: const [0.0, 0.32, 0.70, 1.0],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: OraclyChrome.heroRadius,
                    border: Border.all(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.34),
                      width: 1.05,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        OraclyChrome.heroRadius.topLeft.x - 2,
                      ),
                      border: Border.all(
                        color: OraclyChrome.gold.withValues(alpha: 0.16),
                        width: 0.65,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
