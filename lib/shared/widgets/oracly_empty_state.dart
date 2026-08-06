/// OR-1100 — Premium empty state with CTA.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'oracly_pressable.dart';

class OraclyEmptyState extends StatelessWidget {
  const OraclyEmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.auto_awesome_rounded,
    this.ctaLabel,
    this.onCta,
  });

  final String message;
  final String? title;
  final IconData icon;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.purpleGlow.withValues(alpha: 0.32),
                    AppColors.transparent,
                  ],
                ),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.28),
                  width: AppBorderWidth.hairline,
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.goldLight.withValues(alpha: 0.85),
              ),
            ),
            if (title != null) ...[
              SizedBox(height: AppSpacing.lg),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            if (ctaLabel != null && onCta != null) ...[
              SizedBox(height: AppSpacing.xl),
              _PremiumCta(label: ctaLabel!, onPressed: onCta!),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumCta extends StatelessWidget {
  const _PremiumCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          boxShadow: [
            BoxShadow(
              color: AppColors.goldGlow.withValues(alpha: 0.32),
              blurRadius: 18,
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0D77A), Color(0xFFD4AF37)],
            ),
            borderRadius: AppRadius.lg,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
