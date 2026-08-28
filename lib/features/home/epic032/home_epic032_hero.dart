/// EPIC-032 — Approved horizontal hero card.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../features/daily_energy/navigation/daily_energy_route.dart';
import '../../../features/daily_energy/widgets/daily_energy_moon_hero.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'home_epic032_energy_percent.dart';
import 'home_epic032_spec.dart';
import 'home_epic032_surface.dart';

class HomeEpic032Hero extends StatelessWidget {
  const HomeEpic032Hero({
    super.key,
    this.energyPercent = 82,
    this.alignmentLabel = 'Yüksek Ruhsal Uyum',
    this.description =
        'Bugün sezgilerin güçleniyor. İç sesine güven ve adımlarını bilinçle at.',
    this.onActionPressed,
  });

  final int energyPercent;
  final String alignmentLabel;
  final String description;
  final VoidCallback? onActionPressed;

  static const String _energyLabel = 'BUGÜNÜN ENERJİSİ';

  @override
  Widget build(BuildContext context) {
    final illustrationHeight = HomeEpic032Spec.heroIllustrationHeight(context);
    final illustrationWidth = HomeEpic032Spec.heroIllustrationW(context);

    return HomeEpic032Surface(
      premium: true,
      borderRadius: HomeEpic032Spec.heroRadius,
      padding: HomeEpic032Spec.heroPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: HomeEpic032Spec.heroHeight(context) -
              HomeEpic032Spec.heroPadding.vertical,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: HomeEpic032Spec.heroContentFlex,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _energyLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.44),
                        letterSpacing: 1.6,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: HomeEpic032Spec.heroLabelToPercent),
                    HomeEpic032EnergyPercent(percent: energyPercent),
                    SizedBox(height: HomeEpic032Spec.heroPercentToAlignment),
                    Text(
                      alignmentLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        letterSpacing: 0.35,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.46),
                      ),
                    ),
                    SizedBox(height: HomeEpic032Spec.heroAlignmentToBody),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.82),
                        height: 1.5,
                        letterSpacing: 0.15,
                      ),
                    ),
                    SizedBox(height: HomeEpic032Spec.heroBodyToButton),
                    _DetailButton(
                      onPressed: onActionPressed ??
                          () => DailyEnergyDetailsRoute.open(
                                context,
                                summary: description,
                              ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: HomeEpic032Spec.heroMoonFlex,
              child: Align(
                alignment: Alignment.centerRight,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldGlow.withValues(alpha: 0.28),
                            blurRadius: 48,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: AppColors.purpleGlow.withValues(alpha: 0.16),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const SizedBox(width: 120, height: 120),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: illustrationHeight,
                        maxWidth: illustrationWidth,
                      ),
                      child: DailyEnergyMoonHero(
                        width: illustrationWidth,
                        height: illustrationHeight,
                        enableHero: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailButton extends StatelessWidget {
  const _DetailButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onPressed,
      borderRadius: AppRadius.sm,
      glowShift: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: HomeEpic032Spec.heroButtonMinWidth,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            color: AppColors.surface.withValues(alpha: 0.55),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldGlow.withValues(alpha: 0.18),
                blurRadius: HomeEpic032Spec.cardGlowBlur,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: AppLayout.referencePrimaryButtonPadding,
            child: Text(
              'Detayını Gör',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.goldLight,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
