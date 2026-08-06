/// OR-1090 — Profile hero with stats and premium badge.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/personalization_models.dart';

class ProfileHeroSection extends StatelessWidget {
  const ProfileHeroSection({
    super.key,
    required this.name,
    required this.settings,
    required this.entrance,
    required this.onEditName,
    required this.onPremiumTap,
  });

  final String name;
  final PersonalizationSettings settings;
  final double entrance;
  final VoidCallback onEditName;
  final VoidCallback onPremiumTap;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 20;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ClipRRect(
            borderRadius: AppRadius.xl,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceElevated.withValues(alpha: 0.94),
                      AppColors.surface.withValues(alpha: 0.86),
                    ],
                  ),
                  borderRadius: AppRadius.xl,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.28),
                    width: AppBorderWidth.hairline,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.purpleGlow.withValues(alpha: 0.5),
                                  AppColors.purpleDark,
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.55),
                                width: AppBorderWidth.thin,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.goldGlow.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: AppColors.goldLight,
                            ),
                          ),
                          if (settings.isPremium)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF0D77A),
                                    Color(0xFFD4AF37),
                                  ],
                                ),
                                borderRadius: AppRadius.round,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'PREMIUM',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name.isEmpty ? 'Mistik Yolcu' : name,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            onPressed: onEditName,
                            icon: Icon(
                              Icons.edit_rounded,
                              size: AppSpacing.md,
                              color: AppColors.gold.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      if (!settings.isPremium) ...[
                        TextButton(
                          onPressed: onPremiumTap,
                          child: Text(
                            'Premium\'a Yükselt',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _StatChip(
                            label: 'Seri',
                            value: '${settings.currentStreak} gün',
                            icon: Icons.local_fire_department_rounded,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          _StatChip(
                            label: 'Açılım',
                            value: '${settings.totalReadings}',
                            icon: Icons.auto_stories_rounded,
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _StatChip(
                              label: 'Favori Deste',
                              value: settings.favoriteDeck,
                              icon: Icons.style_rounded,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'Ruhsal Seviye',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: AppRadius.round,
                        child: SizedBox(
                          height: AppSpacing.sm,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor:
                                    settings.spiritualLevel.clamp(0.0, 1.0),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.purple,
                                        AppColors.gold,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        '${(settings.spiritualLevel * 100).round()}% — Derinleşen bağ',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.gold.withValues(alpha: 0.85),
                        ),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: AppColors.primary.withValues(alpha: 0.35),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.18),
          width: AppBorderWidth.hairline,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (compact) return chip;
    return Expanded(child: chip);
  }
}
