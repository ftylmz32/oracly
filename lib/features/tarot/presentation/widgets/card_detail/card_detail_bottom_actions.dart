/// OR-1080 — Bottom premium action bar.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class CardDetailBottomActions extends StatelessWidget {
  const CardDetailBottomActions({
    super.key,
    required this.isFavorite,
    required this.entrance,
    required this.onReading,
    required this.onFavorite,
    required this.onShare,
  });

  final bool isFavorite;
  final double entrance;
  final VoidCallback onReading;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 28;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.0),
                    AppColors.background.withValues(alpha: 0.88),
                    AppColors.background.withValues(alpha: 0.96),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    width: AppBorderWidth.hairline,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _GoldButton(
                          label: 'Açılım Yap',
                          icon: Icons.auto_fix_high_rounded,
                          onPressed: onReading,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      _IconAction(
                        icon: isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        label: 'Favori',
                        active: isFavorite,
                        onTap: onFavorite,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      _IconAction(
                        icon: Icons.ios_share_rounded,
                        label: 'Paylaş',
                        onTap: onShare,
                      ),
                    ],
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

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow.withValues(alpha: 0.32),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.lg,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0D77A), Color(0xFFD4AF37)],
              ),
              borderRadius: AppRadius.lg,
            ),
            child: SizedBox(
              height: AppSpacing.xxl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: AppSpacing.md, color: AppColors.primary),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lg,
        child: Ink(
          width: 56,
          height: AppSpacing.xxl,
          decoration: BoxDecoration(
            borderRadius: AppRadius.lg,
            color: AppColors.surface.withValues(alpha: 0.72),
            border: Border.all(
              color: active
                  ? AppColors.gold.withValues(alpha: 0.55)
                  : AppColors.gold.withValues(alpha: 0.24),
              width: AppBorderWidth.hairline,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppSpacing.md,
                color: active ? AppColors.gold : AppColors.goldLight,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textHint,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
