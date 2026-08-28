/// Bottom nav destination chip — icon glow + gold label.
library;

import 'package:flutter/material.dart';

import '../../core/accessibility/oracly_a11y.dart';
import '../../core/design_system/app_layout.dart';
import '../../core/design_system/oracly_art_direction.dart';
import '../../core/navigation/immersive/immersive_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/craftsmanship_rhythm.dart';
import '../../core/theme/oracly_reduced_motion.dart';
import '../../core/theme/reading_typography.dart';
import 'oracly_bottom_nav_destinations.dart';
import 'oracly_pressable.dart';

export 'oracly_bottom_nav_destinations.dart';

class OraclyBottomNavItem extends StatelessWidget {
  const OraclyBottomNavItem({
    super.key,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final OraclyBottomNavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconGold = selected
        ? OraclyA11y.goldReadable(AppColors.goldLight)
        : AppColors.goldDeep.withValues(alpha: isLight ? 0.72 : 0.74);
    final glow = OraclyArtDirection.clampGoldGlow(selected ? 0.22 : 0.0);

    return OraclyPressable(
      onTap: onTap,
      label: data.label,
      scale: !selected,
      depth: false,
      opacity: !selected,
      haptic: false,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        selected: selected,
        excludeSemantics: true,
        child: OraclyA11y.chromeTextScale(
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? ImmersiveMotion.navActiveScale : 1.0,
                  duration: OraclyReducedMotion.duration(
                    context,
                    ImmersiveMotion.navSelect,
                  ),
                  curve: ImmersiveMotion.pageEnterCurve,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.glowGold.withValues(alpha: glow),
                                blurRadius: 14,
                                spreadRadius: 0.5,
                              ),
                            ]
                          : const [],
                    ),
                    child: Icon(
                      selected ? data.selectedIcon : data.icon,
                      size: AppLayout.navIconSize,
                      color: iconGold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ReadingTypography.metadata().copyWith(
                    fontSize: AppLayout.navLabelSize,
                    height: 1.05,
                    letterSpacing: CraftsmanshipRhythm.microTracking,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? OraclyA11y.goldReadable(AppColors.goldLight)
                        : AppColors.ivory.withValues(
                            alpha: isLight ? 0.76 : 0.74,
                          ),
                  ),
                ),
                AnimatedContainer(
                  duration: OraclyReducedMotion.duration(
                    context,
                    const Duration(milliseconds: 220),
                  ),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(top: 2),
                  height: 2,
                  width: selected ? 14 : 0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.15),
                        AppColors.goldLight.withValues(alpha: 0.95),
                        AppColors.gold.withValues(alpha: 0.15),
                      ],
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.glowGold.withValues(alpha: 0.35),
                              blurRadius: 6,
                            ),
                          ]
                        : const [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
