/// OR-402 / OR-410 — Premium CTA for Tarot Home bottom.
library;

import 'package:flutter/material.dart';

import '../../../../../core/copy/premium_copy.dart';
import 'oracly_sacred_identity.dart';
import 'tarot_home_ornaments.dart';
import 'tarot_home_section_primitives.dart';

/// Bottom premium upsell — crystal-framed luxury gold button.
class TarotHomePremiumCta extends StatelessWidget {
  const TarotHomePremiumCta({
    super.key,
    this.onTap,
  });

  static String get _label => PremiumCopy.ctaExplore;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TarotHomeGoldDivider(),
        SizedBox(height: OraclyRhythm.premiumDividerGap),
        TarotHomeSectionShell(
          lightTier: OraclyLightTier.lowerChamber,
          showOrnaments: false,
          showStars: false,
          padding: EdgeInsets.symmetric(
            horizontal: OraclyRhythm.premiumButtonInset,
            vertical: OraclyRhythm.premiumButtonInset + OraclyRhythm.buttonVerticalClearance,
          ),
          child: TarotHomeLuxuryButton(
            label: _label,
            icon: Icons.workspace_premium_rounded,
            onPressed: onTap,
          ),
        ),
      ],
    );
  }
}
