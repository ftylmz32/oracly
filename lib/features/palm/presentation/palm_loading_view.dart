/// Palm analysis wait — real hand when present, never a Material spinner.
library;

import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../copy/palm_copy.dart';
import 'palm_atmosphere_light.dart';
import 'palm_hand_wait.dart';
import 'palm_photo_frame.dart';

class PalmLoadingView extends StatelessWidget {
  const PalmLoadingView({
    super.key,
    required this.message,
    this.subtitle,
    this.imagePath,
  });

  final String message;
  final String? subtitle;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path != null && File(path).existsSync()) {
      return PalmHandWait(
        message: message,
        subtitle: subtitle,
        path: path,
      );
    }
    return _QuietWait(message: message, subtitle: subtitle);
  }
}

class _QuietWait extends StatelessWidget {
  const _QuietWait({required this.message, this.subtitle});

  final String message;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 220,
          child: PalmPhotoFrame(
            hero: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                OraclyAssetImage(
                  assetPath: AppAssets.palmRitualHero,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  fallback: ColoredBox(
                    color: OraclyChrome.midnight,
                    child: Icon(
                      Icons.front_hand_outlined,
                      color: OraclyChrome.goldLight.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                const PalmAtmosphereLight(),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          message,
          textAlign: TextAlign.center,
          style: ReadingTypography.opening(
            color: OraclyChrome.cream.withValues(alpha: 0.92),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          subtitle ?? PalmCopy.analyzingHint,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: OraclyChrome.cream.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}
