import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../art/tarot_major_card_art.dart';

class TarotCardArt extends StatelessWidget {
  const TarotCardArt({
    super.key,
    required this.image,
    this.height = 200,
    this.width = 130,
    this.compact = false,
  });

  final String image;
  final double height;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 108.0 : height;
    final w = compact ? 72.0 : width;
    final r = compact ? 12.0 : 10.0;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..setEntry(3, 2, 0.001),
      child: Container(
        width: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: compact ? 0.2 : 0.38),
              blurRadius: compact ? 18 : 36,
              spreadRadius: compact ? 0 : 3,
            ),
            BoxShadow(
              color: const Color(0xFFE8A045).withValues(alpha: compact ? 0.15 : 0.25),
              blurRadius: compact ? 12 : 24,
            ),
            ...AppShadows.soft,
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.75), width: 2),
            gradient: LinearGradient(
              colors: [AppColors.gold.withValues(alpha: 0.15), AppColors.card],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r - 2),
            child: SizedBox(
              height: h,
              width: w,
              child: TarotMajorCardArt(
                imageAsset: image,
                showChrome: false,
                fallback: ColoredBox(
                  color: AppColors.card,
                  child: Icon(
                    Icons.auto_awesome,
                    color: AppColors.gold.withValues(alpha: 0.6),
                    size: 32,
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
