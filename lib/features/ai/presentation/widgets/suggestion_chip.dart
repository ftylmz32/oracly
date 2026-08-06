/// OR-1110 — Suggestion chip for AI follow-up prompts.

library;



import 'package:flutter/material.dart';



import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_radius.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_text_styles.dart';

import '../../../../shared/widgets/oracly_pressable.dart';



class SuggestionChip extends StatelessWidget {

  const SuggestionChip({

    super.key,

    required this.label,

    this.onTap,

    this.icon,

  });



  final String label;

  final VoidCallback? onTap;

  final IconData? icon;



  @override

  Widget build(BuildContext context) {

    return OraclyPressable(

      onTap: onTap,

      behavior: HitTestBehavior.opaque,

      child: Container(

        padding: EdgeInsets.symmetric(

          horizontal: AppSpacing.md,

          vertical: AppSpacing.sm,

        ),

        decoration: BoxDecoration(

          borderRadius: AppRadius.round,

          color: AppColors.surface.withValues(alpha: 0.72),

          border: Border.all(

            color: AppColors.gold.withValues(alpha: 0.28),

            width: AppBorderWidth.hairline,

          ),

        ),

        child: Row(

          mainAxisSize: MainAxisSize.min,

          children: [

            if (icon != null) ...[

              Icon(icon, size: 14, color: AppColors.gold),

              SizedBox(width: AppSpacing.xs),

            ],

            Text(

              label,

              style: AppTextStyles.labelMedium.copyWith(

                color: AppColors.goldLight,

              ),

            ),

          ],

        ),

      ),

    );

  }

}

