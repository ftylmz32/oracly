/// Deck back — geometry asset + Oracly brand symbol chrome.
library;

import 'package:flutter/material.dart';

import '../../../core/brand/oracly_brand_mark.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../presentation/widgets/deck/tarot_printed_material.dart';
import 'major_arcana_art.dart';
import 'tarot_card_asset.dart';
import 'tarot_card_back_stars.dart';

class TarotCardBackArt extends StatelessWidget {
  const TarotCardBackArt({
    super.key,
    this.fit = BoxFit.cover,
    this.lightBiasX = 0,
    this.lightBiasY = 0,
  });

  final BoxFit fit;
  final double lightBiasX;
  final double lightBiasY;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF070510)),
        const TarotCardBackStars(),
        OraclyAssetImage(
          assetPath: TarotCardAsset.preview(MajorArcanaArt.cardBack),
          fallbackAsset: MajorArcanaArt.cardBack,
          fit: fit,
          filterQuality: FilterQuality.medium,
          cacheCapPx: TarotCardAsset.previewCapPx,
          fallback: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.goldLight.withValues(alpha: 0.72),
          ),
        ),
        const _SoftCenterGlow(),
        const _BrandSymbol(),
        const _GoldDoubleFrame(),
        TarotPrintedMaterial(
          lightBiasX: lightBiasX,
          lightBiasY: lightBiasY,
          foil: 0.62,
          matte: 0.7,
        ),
      ],
    );
  }
}

class _BrandSymbol extends StatelessWidget {
  const _BrandSymbol();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.38,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth.clamp(28.0, 72.0);
            return OraclyBrandMark(size: side);
          },
        ),
      ),
    );
  }
}

class _SoftCenterGlow extends StatelessWidget {
  const _SoftCenterGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.55,
            colors: [
              AppColors.gold.withValues(alpha: 0.07),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldDoubleFrame extends StatelessWidget {
  const _GoldDoubleFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.62),
              width: 1.05,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.goldLight.withValues(alpha: 0.34),
                  width: 0.65,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
