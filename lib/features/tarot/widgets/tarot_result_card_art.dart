import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';

class TarotCardArt extends StatelessWidget {
  const TarotCardArt({
    super.key,
    required this.image,
    this.height = 348,
    this.compact = false,
  });

  final String image;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final artHeight = compact ? 100.0 : height;
    final artWidth = compact ? 68.0 : double.infinity;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0008)
        ..rotateX(compact ? 0.0 : 0.018),
      child: Container(
        width: artWidth,
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          boxShadow: [
            ...AppShadows.soft,
            BoxShadow(
              color: AppColors.gold.withValues(alpha: .07),
              blurRadius: compact ? 12 : 22,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            border: Border.all(
              color: AppColors.gold.withValues(alpha: .28),
            ),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.md,
            child: Image.asset(
              image,
              height: artHeight,
              width: artWidth,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
