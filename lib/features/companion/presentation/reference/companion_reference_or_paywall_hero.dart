/// OR chamber hero for the paywall — presence, not a store banner.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import 'companion_or_living_core.dart';
import 'companion_or_presence.dart';

class CompanionReferenceOrPaywallHero extends StatelessWidget {
  const CompanionReferenceOrPaywallHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CompanionOrLivingCore(
          size: 88,
          breathe: true,
          presence: CompanionOrPresence.idle,
        ),
        SizedBox(height: AppSpacing.s16),
        Text(
          CompanionCopy.orPaywallTitle,
          textAlign: TextAlign.center,
          style: ReadingTypography.title(
            color: OraclyChrome.cream.withValues(alpha: 0.96),
          ).copyWith(fontSize: 20, height: 1.28),
        ),
        SizedBox(height: AppSpacing.s8),
        Text(
          CompanionCopy.orPaywallLead,
          textAlign: TextAlign.center,
          style: ReadingTypography.body(
            color: OraclyChrome.cream.withValues(alpha: 0.80),
          ),
        ),
      ],
    );
  }
}
