/// Hero ritual outline button — dark glass · thin gold; scales to fit.
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_pressable.dart';

class HomeReferenceHeroDetailButton extends StatelessWidget {
  const HomeReferenceHeroDetailButton({
    super.key,
    this.onPressed,
    this.label = 'Kart çek',
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onPressed,
      borderRadius: AppRadius.round,
      glowShift: true,
      child: OraclyA11y.ensureMinTouch(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.round,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surfaceElevated.withValues(alpha: 0.78),
                AppColors.surface.withValues(alpha: 0.58),
              ],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.68),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.14),
                blurRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 8 : 10,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: ReadingTypography.cta(
                  color: OraclyA11y.goldReadable(AppColors.goldLight),
                ).copyWith(
                  fontSize: compact ? 11.5 : 12.5,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
