/// OR-003.2 — Home hero header: greeting copy and top actions.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/first_session_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import '../theme/home_atmosphere.dart';
import '../theme/home_focus.dart';

/// Reference-accurate home greeting — top actions row, premium copy below.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    this.greeting = FirstSessionCopy.homeGreeting,
    this.userName = FirstSessionCopy.homeGuestName,
    this.subtitle = FirstSessionCopy.homeSubtitleNew,
    this.onMenuTap,
    this.onPremiumTap,
  });

  final String greeting;
  final String userName;
  final String subtitle;
  final VoidCallback? onMenuTap;
  final VoidCallback? onPremiumTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _HeaderIconAction(
              icon: Icons.menu_rounded,
              semanticLabel: 'Evren Haritası',
              onTap: onMenuTap,
            ),
            _HeaderIconAction(
              icon: Icons.workspace_premium_rounded,
              semanticLabel: 'Premium',
              onTap: onPremiumTap,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md + AppSpacing.xs),
        _GreetingCopy(
          greeting: greeting,
          userName: userName,
          subtitle: subtitle,
        ),
      ],
    );
  }
}

class _GreetingCopy extends StatelessWidget {
  const _GreetingCopy({
    required this.greeting,
    required this.userName,
    required this.subtitle,
  });

  final String greeting;
  final String userName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppTextStyles.labelMedium.copyWith(
            color: HomeAtmosphere.temper(
              AppColors.textSecondary.withValues(alpha: 0.74),
              HomeFocusZone.header,
              strength: 0.08,
            ),
            height: 1.35,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          userName,
          style: AppTextStyles.headlineLarge.copyWith(
            color: Color.lerp(
              AppColors.textPrimary.withValues(alpha: 0.90),
              HomeAtmosphere.wisdomGold.withValues(alpha: 0.88),
              0.08,
            ),
            height: 1.12,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: HomeAtmosphere.temper(
              AppColors.textSecondary.withValues(alpha: 0.68),
              HomeFocusZone.header,
              strength: 0.10,
            ),
            height: 1.55,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _HeaderIconAction extends StatelessWidget {
  const _HeaderIconAction({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: OraclyPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.xxl),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: AppSpacing.md + AppSpacing.xs,
            color: HomeAtmosphere.temper(
              AppColors.icon.withValues(alpha: 0.88),
              HomeFocusZone.header,
              strength: 0.06,
            ),
          ),
        ),
      ),
    );
  }
}
