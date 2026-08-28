/// Reference membership / premium card.
library;

import 'package:flutter/material.dart';

import '../../../core/copy/premium_copy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'profile_reference_card_shell.dart';
import 'profile_reference_membership_button.dart';
import 'profile_reference_tokens.dart';
import 'profile_surface_weight.dart';

class ProfileReferenceMembershipCard extends StatelessWidget {
  const ProfileReferenceMembershipCard({
    super.key,
    required this.isPremium,
    required this.onPrimaryTap,
  });

  final bool isPremium;
  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final status = isPremium ? 'Premium Üye' : 'Standart erişim';
    final detail = isPremium
        ? 'Premium üyeliğin aktif.'
        : PremiumCopy.ctaUnavailable;

    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.utility,
      borderRadius: ProfileReferenceTokens.membershipRadius,
      padding: ProfileReferenceTokens.membershipPadding,
      glowStrength: 1.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _PremiumBadge(isPremium: isPremium),
              const Spacer(),
              Icon(
                Icons.workspace_premium_rounded,
                color: palette.goldLight.withValues(alpha: 0.72),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.goldLight.withValues(alpha: 0.94),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: AppTextStyles.bodySmall.copyWith(
              color: palette.textSecondary.withValues(alpha: 0.78),
              height: 1.25,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          ProfileReferenceMembershipButton(
            label: PremiumCopy.ctaExplore,
            onPressed: onPrimaryTap,
          ),
        ],
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: isPremium
              ? [AppColors.goldLight, AppColors.gold, AppColors.goldDeep]
              : [
                  AppColors.surface.withValues(alpha: 0.65),
                  AppColors.purpleDark.withValues(alpha: 0.55),
                ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isPremium ? 0.45 : 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          isPremium ? 'PREMIUM' : 'STANDART',
          style: AppTextStyles.caption.copyWith(
            color: isPremium ? AppColors.purpleDark : palette.goldLight,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
