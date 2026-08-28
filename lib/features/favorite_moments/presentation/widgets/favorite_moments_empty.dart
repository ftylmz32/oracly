/// Empty collection — atmospheric plate, honest sentence, no fake moments.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_empty_atmosphere.dart';
import '../../copy/favorite_moments_copy.dart';

class FavoriteMomentsEmpty extends StatelessWidget {
  const FavoriteMomentsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s32,
          AppSpacing.s12,
          AppSpacing.s32,
          AppSpacing.s32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OraclyEmptyAtmosphere(
              assetPath: AppAssets.dailyMoonPhotoreal,
              size: 104,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              FavoriteMomentsCopy.emptyTitle,
              textAlign: TextAlign.center,
              style: ReadingTypography.title(
                color: OraclyChrome.goldLight.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              FavoriteMomentsCopy.emptyBody,
              textAlign: TextAlign.center,
              style: ReadingTypography.body(
                color: OraclyChrome.cream.withValues(alpha: 0.74),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
