/// Brand-new Profile — calm entry points, no fake stats.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_button.dart';
import '../../../shared/widgets/oracly_empty_atmosphere.dart';
import '../copy/profile_copy.dart';

class ProfileReferenceNewUserEmptyState extends StatelessWidget {
  const ProfileReferenceNewUserEmptyState({
    super.key,
    required this.onDaily,
    required this.onOr,
    required this.onFirstDiscovery,
  });

  final VoidCallback onDaily;
  final VoidCallback onOr;
  final VoidCallback onFirstDiscovery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: OraclyEmptyAtmosphere(
              assetPath: AppAssets.homeHeroMoon,
              size: 72,
            ),
          ),
          SizedBox(height: AppSpacing.s12),
          Text(
            ProfileCopy.newUserTitle,
            style: ReadingTypography.body(
              color: OraclyChrome.cream.withValues(alpha: 0.90),
            ),
          ),
          SizedBox(height: AppSpacing.s16),
          OraclyButton(
            text: ProfileCopy.newUserDailyCta,
            onPressed: onDaily,
            type: OraclyButtonType.secondary,
            size: OraclyButtonSize.large,
          ),
          SizedBox(height: AppSpacing.s12),
          OraclyButton(
            text: ProfileCopy.newUserOrCta,
            onPressed: onOr,
            type: OraclyButtonType.secondary,
            size: OraclyButtonSize.large,
          ),
          SizedBox(height: AppSpacing.s12),
          OraclyButton(
            text: ProfileCopy.newUserFirstCta,
            onPressed: onFirstDiscovery,
            type: OraclyButtonType.ghost,
            size: OraclyButtonSize.large,
          ),
        ],
      ),
    );
  }
}

