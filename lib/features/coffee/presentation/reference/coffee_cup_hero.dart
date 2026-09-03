/// Full ritual plate — intrinsic height from asset, never a forced landscape strip.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import '../../copy/coffee_copy.dart';
import 'coffee_cup_art.dart';

class CoffeeCupHero extends StatelessWidget {
  const CoffeeCupHero({super.key});

  /// `coffee_ritual_hero.webp` — hero_tall export from reference plate master.
  static const Size assetPx = Size(941, 830);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = w * assetPx.height / assetPx.width;
          return Semantics(
            label: CoffeeCopy.screenTitle,
            child: SizedBox(
              width: w,
              height: h,
              child: OraclyAssetImage(
                assetPath: AppAssets.coffeeRitualHero,
                width: w,
                height: h,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                fallback: CustomPaint(
                  size: Size(w, h),
                  painter: const CoffeeCupFallback(phase: 0.12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
