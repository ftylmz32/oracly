/// Compact Destem face — artwork only, preview decode budget.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import '../../deck/oracly_tarot_card.dart';

class DestemCardArt extends StatelessWidget {
  const DestemCardArt({
    super.key,
    required this.card,
    this.height = 120,
    this.width = 78,
  });

  final OraclyTarotCard card;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: OraclyChrome.gold.withValues(alpha: 0.18),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: OraclyAssetImage(
          assetPath: card.visualAsset,
          fit: BoxFit.cover,
          cacheCapPx: 320,
          filterQuality: FilterQuality.medium,
          fallback: ColoredBox(
            color: OraclyChrome.midnight.withValues(alpha: 0.85),
            child: Icon(
              Icons.style_outlined,
              color: OraclyChrome.goldLight.withValues(alpha: 0.55),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
