/// Reference Günlük Enerjin horizontal card.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/app_radius.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/daily_energy/daily_energy_constants.dart';
import '../../../features/daily_energy/navigation/daily_energy_route.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'home_reference_card_shell.dart';
import 'home_reference_tokens.dart';

class HomeReferenceDailyEnergyCard extends StatelessWidget {
  const HomeReferenceDailyEnergyCard({
    super.key,
    this.description =
        'Bugün sezgilerin güçleniyor. İç sesine güven ve adımlarını bilinçle at.',
  });

  final String description;

  static const String _title = 'GÜNLÜK ENERJİN';

  @override
  Widget build(BuildContext context) {
    return HomeReferenceCardShell(
      borderRadius: HomeReferenceTokens.dailyRadius,
      padding: HomeReferenceTokens.dailyPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.goldLight.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      height: 1.32,
                    ),
                  ),
                  SizedBox(height: HomeReferenceTokens.dailyTitleToBody),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.82),
                      height: 1.55,
                      letterSpacing: 0.15,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: HomeReferenceTokens.dailyTextToButtons),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      _OutlineChip(
                        label: 'Detayını Gör',
                        icon: Icons.visibility_outlined,
                        onPressed: () => DailyEnergyDetailsRoute.open(
                          context,
                          summary: description,
                        ),
                      ),
                      _OutlineChip(
                        label: 'Kart çek',
                        icon: Icons.auto_awesome_rounded,
                        onPressed: () =>
                            OraclyNavigationService.startDailyCardDraw(context),
                      ),
                      _OutlineChip(
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: HomeReferenceTokens.dailyIllustrationMaxHeight,
              ),
              child: Hero(
                tag: DailyEnergyHeroTags.moonIllustration,
                child: Material(
                  type: MaterialType.transparency,
                  child: OraclyAssetImage(
                    assetPath: AppAssets.dailyMoonPhotoreal,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    fallback: Icon(
                      Icons.nightlight_round,
                      size: 96,
                      color: AppColors.goldLight.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineChip extends StatefulWidget {
  const _OutlineChip({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_OutlineChip> createState() => _OutlineChipState();
}

class _OutlineChipState extends State<_OutlineChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: widget.onPressed,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      borderRadius: AppRadius.sm,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: AppLayout.referenceOutlineButtonPadding,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
