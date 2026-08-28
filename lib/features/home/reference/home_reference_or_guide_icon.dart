/// OR guide icon well — shared Home chrome motif.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import 'home_reference_tokens.dart';

class HomeReferenceOrGuideIconWell extends StatelessWidget {
  const HomeReferenceOrGuideIconWell({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final well = compact
        ? HomeReferenceTokens.orGuideIconWell - 4
        : HomeReferenceTokens.orGuideIconWell;
    final icon = compact
        ? HomeReferenceTokens.orGuideIconSize - 2
        : HomeReferenceTokens.orGuideIconSize;
    return Container(
      width: well,
      height: well,
      decoration: BoxDecoration(
        borderRadius: HomeReferenceTokens.orGuideRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.14),
            AppColors.surface.withValues(alpha: 0.42),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.20),
        ),
      ),
      child: Center(
        child: OraclyAssetImage(
          assetPath: AppAssets.homeOrGuide,
          width: icon,
          height: icon,
          fit: BoxFit.cover,
          cacheCapPx: 384,
          fallback: Icon(
            Icons.auto_awesome_rounded,
            size: icon,
            color: AppColors.goldLight.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}