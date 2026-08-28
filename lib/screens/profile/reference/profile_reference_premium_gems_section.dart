/// Premium footer — gold accent, short value, not a giant ad.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/copy/premium_copy.dart';
import '../../../core/copy/resilience_copy.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/premium/providers/premium_providers.dart';
import '../../../shared/widgets/oracly_button.dart';
import '../copy/profile_copy.dart';
import 'profile_reference_card_shell.dart';
import 'profile_surface_weight.dart';

class ProfileReferencePremiumGemsSection extends ConsumerWidget {
  const ProfileReferencePremiumGemsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumStatusProvider);
    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.utility,
      glowStrength: 0.62,
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: OraclyChrome.gold.withValues(alpha: 0.55),
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: _PremiumCard(
            isPremium: premium.isPremium,
            premiumLoaded: premium.loaded,
            busy: premium.busy,
          ),
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.isPremium,
    required this.premiumLoaded,
    required this.busy,
  });

  final bool isPremium;
  final bool premiumLoaded;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    if (!premiumLoaded) {
      return Text(
        ResilienceCopy.profileLoading,
        style: ReadingTypography.body(color: palette.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PremiumCopy.heroTitle,
          softWrap: true,
          style: AppTextStyles.title.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: palette.goldLight.withValues(alpha: 0.95),
          ),
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          isPremium ? PremiumCopy.activeBody : PremiumCopy.heroSubtitle,
          softWrap: true,
          style: ReadingTypography.bodyCore(color: palette.textSecondary),
        ),
        SizedBox(height: AppSpacing.s12),
        if (!isPremium)
          OraclyButton(
            text: ProfileCopy.premiumDiscoverCta,
            onPressed: () => OraclyNavigationService.openPremium(context),
            type: OraclyButtonType.secondary,
          )
        else
          Text(
            ProfileCopy.premiumActive,
            style: ReadingTypography.bodyCore(
              color: palette.goldLight.withValues(alpha: 0.90),
            ),
          ),
        if (busy) SizedBox(height: AppSpacing.s8),
      ],
    );
  }
}
