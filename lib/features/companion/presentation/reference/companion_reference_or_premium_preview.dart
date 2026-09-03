/// Free OR chamber — meet OR, sample talk, then OR-specific paywall.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import 'companion_or_living_core.dart';
import 'companion_or_presence.dart';
import 'companion_or_presence_entry.dart';
import 'companion_reference_or_paywall_host.dart';
import 'companion_reference_or_premium_sample.dart';
import 'companion_reference_tokens.dart';

class CompanionReferenceOrPremiumPreview extends StatelessWidget {
  const CompanionReferenceOrPremiumPreview({
    super.key,
    this.personality = 'mystical',
  });

  final String personality;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final emblemSize = CompanionReferenceTokens.premiumEmblemFor(context);
        final gap = CompanionReferenceTokens.sectionGapFor(context);
        final breath = CompanionReferenceTokens.verticalBreathFor(context);
        return CompanionReferenceTokens.fillScrollPane(
          constraints: constraints,
          padding: EdgeInsets.symmetric(
            horizontal: CompanionReferenceTokens.screenHorizontal,
            vertical: breath,
          ),
          children: [
            CompanionOrPresenceEntry(
              emblem: CompanionOrLivingCore(
                size: emblemSize,
                breathe: true,
                presence: CompanionOrPresence.idle,
              ),
              body: Column(
                children: [
                  SizedBox(height: gap * 0.65),
                  Text(
                    CompanionCopy.orPremiumHeadline,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.title(
                      color: OraclyChrome.cream.withValues(alpha: 0.95),
                    ).copyWith(fontSize: 20, height: 1.28),
                  ),
                  SizedBox(height: AppSpacing.s8),
                  Text(
                    CompanionCopy.orPremiumLead,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.body(
                      color: OraclyChrome.cream.withValues(alpha: 0.82),
                    ),
                  ),
                  SizedBox(height: AppSpacing.s8),
                  Text(
                    CompanionCopy.orPremiumPersonality,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.bodySmall(
                      color: OraclyChrome.goldLight.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),
            const CompanionReferenceOrPremiumSample(),
            SizedBox(height: gap),
            const CompanionReferenceOrPaywallHost(showHero: false),
          ],
        );
      },
    );
  }
}
