/// Dream hero — large circular sleeping/moon illustration (reference).
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/performance/oracly_decode_cache.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import 'dream_reference_tokens.dart';

class DreamReferenceIllustrationCard extends StatelessWidget {
  const DreamReferenceIllustrationCard({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final diameter =
        height ?? DreamReferenceTokens.illustrationHeight(context);

    return SizedBox(
      height: diameter,
      width: double.infinity,
      child: Center(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OraclyChrome.midnight,
              border: Border.all(
                color: OraclyChrome.goldHighlight.withValues(alpha: 0.68),
                width: AppBorderWidth.thin,
              ),
              boxShadow: [
                BoxShadow(
                  color: OraclyChrome.violet.withValues(alpha: 0.28),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: OraclyChrome.gold.withValues(alpha: 0.14),
                  blurRadius: 22,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: DreamReferenceTokens.illustrationInnerPadding,
                child: Image.asset(
                  AppAssets.dailyEnergyMoon,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  cacheWidth: oraclyDecodeCachePx(
                    diameter,
                    MediaQuery.devicePixelRatioOf(context),
                  ),
                  semanticLabel: OraclyL10n.t(L10nKeys.dream),
                  errorBuilder: (_, _, _) => Icon(
                    Icons.nightlight_round,
                    color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                    size: diameter * 0.28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DreamReferenceThumbnail extends StatelessWidget {
  const DreamReferenceThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    const size = DreamReferenceTokens.recentThumbSize;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: DreamReferenceTokens.recentThumbRadius,
        color: OraclyChrome.midnight,
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.42),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: ClipRRect(
        borderRadius: DreamReferenceTokens.recentThumbRadius,
        child: OraclyAssetImage(
          assetPath: AppAssets.dailyEnergyMoon,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
