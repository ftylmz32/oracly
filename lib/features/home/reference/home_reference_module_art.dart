/// Image-first Home tile art — cinematic illustration, quiet preview badge.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/preview_capability_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_asset_image.dart';

class HomeReferenceModuleArt extends StatelessWidget {
  const HomeReferenceModuleArt({
    super.key,
    required this.asset,
    required this.fallbackIcon,
    this.preview = false,
  });

  final String asset;
  final IconData fallbackIcon;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.surface.withValues(alpha: 0.55),
            child: OraclyAssetImage(
              assetPath: asset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              fallback: Icon(
                fallbackIcon,
                color: AppColors.goldLight.withValues(alpha: 0.78),
              ),
            ),
          ),
          if (preview)
            Positioned(
              top: 5,
              right: 5,
              child: Text(
                PreviewCapabilityCopy.badge,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gold.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w500,
                  fontSize: 6.5,
                  height: 1,
                  letterSpacing: 0.25,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
