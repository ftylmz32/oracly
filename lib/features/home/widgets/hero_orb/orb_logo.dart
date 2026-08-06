/// OR-031B — Layer 7: large bright OR seal.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'orb_constants.dart';

/// OR mark — large, sharp, luminous gold centerpiece.
class OrbLogo extends StatelessWidget {
  const OrbLogo({super.key, required this.size});

  final double size;

  static const String _mark = 'OR';

  @override
  Widget build(BuildContext context) {
    final fontSize = OrbLayout.logoFontSize(size);
    final tracking = OrbLayout.logoTracking(size);

    final base = AppTextStyles.displaySmall.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: tracking,
      height: 1.0,
    );

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: Offset(0, size * 0.004),
            child: Text(
              _mark,
              style: base.copyWith(
                color: AppColors.purpleDark.withValues(alpha: 0.55),
              ),
            ),
          ),
          Text(
            _mark,
            style: base.copyWith(
              color: AppColors.gold.withValues(alpha: 0.85),
              shadows: const [
                Shadow(
                  color: AppColors.goldGlow,
                  blurRadius: AppSpacing.md,
                ),
                Shadow(
                  color: AppColors.purpleGlow,
                  blurRadius: AppSpacing.sm,
                ),
              ],
            ),
          ),
          Text(
            _mark,
            style: base.copyWith(
              color: AppColors.goldLight,
              shadows: [
                Shadow(
                  color: AppColors.goldLight.withValues(alpha: 0.70),
                  blurRadius: AppSpacing.xs,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
