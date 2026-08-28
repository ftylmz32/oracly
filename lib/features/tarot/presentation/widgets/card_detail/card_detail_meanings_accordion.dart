/// OR-1080 — Single-expand accordion for card meanings.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'card_detail_models.dart';

class CardDetailMeaningsAccordion extends StatelessWidget {
  const CardDetailMeaningsAccordion({
    super.key,
    required this.meanings,
    required this.expandedKey,
    required this.onToggle,
    required this.entrance,
    required this.accent,
  });

  final CardMeaningSections meanings;
  final String? expandedKey;
  final ValueChanged<String> onToggle;
  final double entrance;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final slide = (1 - entrance) * 18;
    return Opacity(
      opacity: entrance.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, slide),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Anlamlar',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.goldLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              ...CardMeaningSections.sectionTitles.map((section) {
                final key = section.$1;
                final title = section.$2;
                final icon = section.$3;
                final expanded = expandedKey == key;
                return _MeaningPanel(
                  title: title,
                  icon: icon,
                  body: meanings.textForKey(key),
                  expanded: expanded,
                  accent: accent,
                  onTap: () => onToggle(key),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeaningPanel extends StatelessWidget {
  const _MeaningPanel({
    required this.title,
    required this.icon,
    required this.body,
    required this.expanded,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String body;
  final bool expanded;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: AppRadius.lg,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AnimatedContainer(
            duration: AppDuration.normal,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceElevated.withValues(
                    alpha: expanded ? 0.94 : 0.82,
                  ),
                  AppColors.surface.withValues(
                    alpha: expanded ? 0.88 : 0.76,
                  ),
                ],
              ),
              borderRadius: AppRadius.lg,
              border: Border.all(
                color: expanded
                    ? accent.withValues(alpha: 0.55)
                    : AppColors.gold.withValues(alpha: 0.22),
                width: expanded ? AppBorderWidth.thin : AppBorderWidth.hairline,
              ),
              boxShadow: expanded ? AppShadows.soft : null,
            ),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: AppSpacing.card,
                      child: Row(
                        children: [
                          Icon(icon, size: AppSpacing.md, color: accent),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.goldLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: expanded ? 0.5 : 0,
                            duration: AppDuration.fast,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.gold.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.card.left,
                          0,
                          AppSpacing.card.right,
                          AppSpacing.card.bottom,
                        ),
                        child: Text(
                          body,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.58,
                          ),
                        ),
                      ),
                      crossFadeState: expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: AppDuration.normal,
                      sizeCurve: Curves.easeOutCubic,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stagger entrance helper for card detail sections.
double cardDetailSectionEntrance(int index, double master) {
  final start = index * 0.07;
  final end = start + 0.28;
  if (master <= start) return 0;
  if (master >= end) return 1;
  return Curves.easeOutCubic.transform(
    ((master - start) / (end - start)).clamp(0.0, 1.0),
  );
}
