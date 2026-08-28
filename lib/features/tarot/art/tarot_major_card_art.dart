/// Major Arcana face — scene asset + Flutter numeral/title chrome.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../presentation/widgets/deck/tarot_printed_material.dart';
import 'major_arcana_art.dart';
import 'minor_arcana_art.dart';
import 'tarot_card_asset.dart';
import 'tarot_card_face_chrome.dart';

class TarotMajorCardArt extends StatelessWidget {
  const TarotMajorCardArt({
    super.key,
    required this.imageAsset,
    this.fit = BoxFit.cover,
    this.showChrome = true,
    this.fallback,
    this.preview = true,
  });

  final String imageAsset;
  final BoxFit fit;
  final bool showChrome;
  final Widget? fallback;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final minor = MinorArcanaArt.chromeFor(imageAsset);
    final majorId =
        minor == null ? MajorArcanaArt.idFromAsset(imageAsset) : null;
    final numeral = minor?.numeral ??
        (majorId != null ? MajorArcanaArt.romanFor(majorId) : null);
    final title = minor?.title ??
        (majorId != null ? MajorArcanaArt.titleFor(majorId) : null);
    return Stack(
      fit: StackFit.expand,
      children: [
        OraclyAssetImage(
          assetPath: preview
              ? TarotCardAsset.preview(imageAsset)
              : TarotCardAsset.full(imageAsset),
          fallbackAsset: imageAsset,
          fit: fit,
          filterQuality: preview ? FilterQuality.medium : FilterQuality.high,
          cacheCapPx: preview
              ? TarotCardAsset.previewCapPx
              : TarotCardAsset.fullCapPx,
          fallback: fallback ??
              ColoredBox(
                color: AppColors.purpleDark,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.goldLight.withValues(alpha: 0.72),
                ),
              ),
        ),
        const TarotCardGoldFrame(),
        const TarotPrintedMaterial(foil: 0.42, matte: 0.4),
        if (showChrome && numeral != null && title != null) ...[
          Positioned(
            top: 7,
            left: 8,
            right: 8,
            child: TarotCardTitlePlaque(
              text: numeral,
              letterSpacing: 2.2,
              size: 11,
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 7,
            child: TarotCardTitlePlaque(
              text: title,
              letterSpacing: 1.3,
              size: 10,
            ),
          ),
        ],
      ],
    );
  }
}
