/// EPIC-031 fan cards — painted backs + hero face asset.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import 'tarot_epic031_card_face.dart';

class TarotEpic031BackCard extends StatelessWidget {
  const TarotEpic031BackCard({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.50),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          size: Size(width, height),
          painter: const TarotEpic031CardFace(),
        ),
      ),
    );
  }
}

class TarotEpic031FaceCard extends StatelessWidget {
  const TarotEpic031FaceCard({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: const Color(0xFF0A041A),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.58),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.52),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.22),
            blurRadius: 20,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: AppColors.purpleGlow.withValues(alpha: 0.14),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: OraclyAssetImage(
          assetPath: AppAssets.tarotHero,
          width: width,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
