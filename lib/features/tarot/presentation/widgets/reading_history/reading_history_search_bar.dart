/// OR-1070 — Premium glass search bar.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class ReadingHistorySearchBar extends StatelessWidget {
  const ReadingHistorySearchBar({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
          BoxShadow(
            color: AppColors.glowPurple.withValues(alpha: 0.10),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: OraclyL10n.t('tarot.history.search_hint'),
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.gold.withValues(alpha: 0.75),
                size: AppSpacing.lg,
              ),
              filled: true,
              fillColor: AppColors.surface.withValues(alpha: 0.72),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + AppSpacing.xs,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.lg,
                borderSide: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  width: AppBorderWidth.hairline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.lg,
                borderSide: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.22),
                  width: AppBorderWidth.hairline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.lg,
                borderSide: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.55),
                  width: AppBorderWidth.thin,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
