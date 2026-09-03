/// Dream entry hero — approved portal plate from reference art master.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import '../../copy/dream_copy.dart';

class DreamReferenceEntryHero extends StatelessWidget {
  const DreamReferenceEntryHero({super.key});

  /// `dream_entry_hero.webp` — hero_wide export from approved reference plate.
  static const Size assetPx = Size(500, 250);

  @override
  Widget build(BuildContext context) {
    final titleSize = MediaQuery.sizeOf(context).width < 360 ? 18.0 : 21.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w * assetPx.height / assetPx.width;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  label: DreamCopy.screenTitle,
                  child: OraclyAssetImage(
                    assetPath: AppAssets.dreamEntryHero,
                    width: w,
                    height: h,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    fallback: ColoredBox(color: OraclyChrome.midnight),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withValues(alpha: 0.62),
                        Colors.black.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DreamCopy.heroHeadline,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: ReadingTypography.title(
                          color: OraclyChrome.cream.withValues(alpha: 0.96),
                        ).copyWith(fontSize: titleSize, height: 1.28),
                      ),
                      SizedBox(height: AppSpacing.s4),
                      Text(
                        DreamCopy.heroSubline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ReadingTypography.bodySmall(
                          color: OraclyChrome.cream.withValues(alpha: 0.74),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}