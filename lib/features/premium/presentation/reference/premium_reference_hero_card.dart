/// Premium hero — exclusive chamber image; Flutter owns the invitation.
library;

import 'package:flutter/material.dart';

import '../../../../core/brand/oracly_brand_mark.dart';
import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/craftsmanship_rhythm.dart';
import '../../../../core/theme/reading_typography.dart';
import 'premium_chamber_plate.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceHeroCard extends StatelessWidget {
  const PremiumReferenceHeroCard({super.key, this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final glow = active ? 0.32 : 0.18;
    return OraclySoftReveal(
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: OraclyChrome.heroRadius,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5C3A1E).withValues(alpha: glow),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: OraclyChrome.gold.withValues(alpha: 0.08),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const PremiumChamberPlate(),
          ),
          SizedBox(height: PremiumReferenceTokens.heroToIntro),
          const OraclyBrandMark(size: 40, forLauncher: true),
          const SizedBox(height: 10),
          Text(
            PremiumCopy.heroTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(fontSize: 12).copyWith(
              letterSpacing: 2.2,
              color: OraclyChrome.goldLight.withValues(alpha: 0.92),
            ),
          ),
          SizedBox(height: CraftsmanshipRhythm.afterTitle),
          Text(
            PremiumCopy.heroSubtitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.opening(
              color: OraclyChrome.cream.withValues(alpha: 0.90),
            ),
          ),
          if (PremiumCopy.heroLead.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              PremiumCopy.heroLead,
              textAlign: TextAlign.center,
              style: ReadingTypography.footnote(
                color: OraclyChrome.cream.withValues(alpha: 0.62),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
