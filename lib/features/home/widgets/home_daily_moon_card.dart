/// Reference home — daily moon card: text left, moon right, three outlined actions.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/daily_energy/daily_energy_constants.dart';
import '../../../features/daily_energy/navigation/daily_energy_route.dart';
import '../../../shared/widgets/oracly_card.dart';
import '../theme/home_architecture.dart';
import '../theme/home_reward.dart';
import 'daily_energy/energy_constants.dart';
import 'daily_energy/energy_description.dart';
import 'daily_energy/energy_illustration.dart';
import 'daily_energy/energy_title.dart';

/// Bottom daily moon card — text left, illustration right, three outline chips.
class HomeDailyMoonCard extends StatelessWidget {
  const HomeDailyMoonCard({
    super.key,
    this.description =
        'Bugün sezgilerin güçleniyor. İç sesine güven ve adımlarını bilinçle at.',
  });

  final String description;

  static const double _illustrationHeight =
      AppSpacing.xxl + AppSpacing.xxl + AppSpacing.xl + AppSpacing.md + 4;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: EnergyDecorations.shell,
      child: OraclyCard(
        showBorder: false,
        showShadow: false,
        clipBehavior: Clip.none,
        gradient: EnergyDecorations.cardSurface,
        padding: EdgeInsets.only(
          left: AppSpacing.insetCard + AppSpacing.xs,
          right: 0,
          top: AppSpacing.insetCard,
          bottom: AppSpacing.insetCard + 2,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.only(right: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const EnergyTitle(),
                        SizedBox(height: EnergySpacing.titleToBody),
                        EnergyDescription(description: description),
                        SizedBox(height: EnergySpacing.bodyToAction),
                        Wrap(
                          spacing: AppSpacing.s8,
                          runSpacing: AppSpacing.s8,
                          children: [
                            _OutlineActionChip(
                              label: 'Detayını Gör',
                              icon: Icons.visibility_outlined,
                              onPressed: () => DailyEnergyDetailsRoute.open(
                                context,
                                summary: description,
                              ),
                            ),
                            _OutlineActionChip(
                              label: 'Kart çek',
                              icon: Icons.auto_awesome_rounded,
                              onPressed: () => OraclyNavigationService
                                  .startDailyCardDraw(context),
                            ),
                            _OutlineActionChip(
                              label: 'Günlük not',
                              icon: Icons.edit_outlined,
                              onPressed: () => DailyEnergyDetailsRoute.open(
                                context,
                                summary: description,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: _illustrationHeight,
                    child: Hero(
                      tag: DailyEnergyHeroTags.moonIllustration,
                      child: Material(
                        type: MaterialType.transparency,
                        child: const EnergyIllustration(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineActionChip extends StatefulWidget {
  const _OutlineActionChip({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_OutlineActionChip> createState() => _OutlineActionChipState();
}

class _OutlineActionChipState extends State<_OutlineActionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scale = HomeReward.pressScale(_pressed && enabled);

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: scale,
        duration: HomeReward.press,
        curve: HomeReward.curve,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 1,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.sm,
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.28),
            ),
            color: AppColors.surface.withValues(alpha: 0.28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: AppColors.goldLight.withValues(alpha: 0.78),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.goldLight.withValues(alpha: 0.82),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
