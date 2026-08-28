/// Reference home hero — moon illustration, today's energy, detail action.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/daily_energy/navigation/daily_energy_route.dart';
import '../../../features/daily_energy/widgets/daily_energy_moon_hero.dart';
import '../../../shared/widgets/oracly_card.dart';
import '../theme/home_architecture.dart';
import 'daily_energy/energy_action.dart';
import 'daily_energy/energy_constants.dart';

/// Large hero card — moon, energy readout, description, secondary CTA.
class HomeEnergyHeroCard extends StatelessWidget {
  const HomeEnergyHeroCard({
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

  static const double _cardHeight = 296;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: EnergyDecorations.shell,
      child: OraclyCard(
        showBorder: false,
        showShadow: false,
        clipBehavior: Clip.none,
        gradient: EnergyDecorations.cardSurface,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.insetCard + AppSpacing.xs,
          AppSpacing.insetCard,
          AppSpacing.insetCard + AppSpacing.xs,
          AppSpacing.insetCard + AppSpacing.sm,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: HomeArchitectureOverlay(
                borderRadius: AppRadius.lg,
                proximity: HomeOrbProximity.medium,
                detail: HomeSurfaceDetail.standard,
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: AppRadius.lg,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x18000000),
                        Color(0x06000000),
                        Color(0x14000000),
                      ],
                      stops: [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: _cardHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: DailyEnergyMoonHero(
                        width: 132,
                        height: 156,
                        enableHero: false,
                      ),
                    ),
                  ),
                  Text(
                    'BUGÜNÜN ENERJİSİ',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.44),
                      letterSpacing: 1.6,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: AppSpacing.s8),
                  Text(
                    '$energyPercent%',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.hero.copyWith(
                      fontSize: 56,
                      height: 0.92,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -3.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: AppColors.gold.withValues(alpha: 0.94),
                    ),
                  ),
                  SizedBox(height: AppSpacing.s8),
                  Text(
                    alignmentLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 14,
                      height: 1.55,
                      letterSpacing: 0.35,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.46),
                    ),
                  ),
                  SizedBox(height: AppSpacing.s12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.82),
                      height: 1.55,
                      letterSpacing: 0.15,
                    ),
                  ),
                  SizedBox(height: AppSpacing.s16),
                  Align(
                    alignment: Alignment.center,
                    child: EnergyAction(
                      onPressed: onActionPressed ??
                          () => DailyEnergyDetailsRoute.open(
                                context,
                                summary: description,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
