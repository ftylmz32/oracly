/// Short cinematic invitation — the value sits under the plate.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/reading_typography.dart';
import 'premium_chamber_plate.dart';
import 'premium_quiet_action.dart';
import 'premium_reference_value_highlights.dart';

class PremiumReferenceHeroCard extends StatelessWidget {
  const PremiumReferenceHeroCard({
    super.key,
    this.active = false,
    this.onSeePlans,
  });

  final bool active;
  final VoidCallback? onSeePlans;

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
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const PremiumChamberPlate(
              ratio: PremiumChamberPlate.wideAspect,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            PremiumCopy.heroTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.sectionLabel(fontSize: 13).copyWith(
              letterSpacing: 1.6,
              color: OraclyChrome.goldLight.withValues(alpha: 0.96),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            PremiumCopy.heroSubtitle,
            textAlign: TextAlign.center,
            softWrap: true,
            style: ReadingTypography.body(
              color: OraclyChrome.cream.withValues(alpha: 0.92),
            ),
          ),
          if (PremiumCopy.heroLead.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              PremiumCopy.heroLead,
              textAlign: TextAlign.center,
              style: ReadingTypography.footnote(
                color: OraclyChrome.cream.withValues(alpha: 0.62),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const PremiumReferenceValueHighlights(),
          if (onSeePlans != null) ...[
            const SizedBox(height: 16),
            Align(
              child: PremiumQuietAction(
                label: PremiumCopy.seePlans,
                onTap: onSeePlans!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
