/// Empty-state / thread hero -- large portrait overlapping intro card.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';
import 'companion_luna_hero_portrait.dart';
import 'companion_reference_tokens.dart';

class CompanionLunaIntroCard extends StatelessWidget {
  const CompanionLunaIntroCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact
        ? CompanionReferenceTokens.heroHeightCompact
        : CompanionReferenceTokens.heroHeight;
    final overlap = CompanionReferenceTokens.heroCardOverlap;
    return SizedBox(
      height: h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final portraitW =
              constraints.maxWidth * CompanionReferenceTokens.heroPortraitFactor;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: portraitW,
                child: const CompanionLunaHeroPortrait(),
              ),
              Positioned(
                left: portraitW - overlap,
                right: 0,
                top: compact ? 10 : 16,
                bottom: compact ? 10 : 16,
                child: const _IntroPanel(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel();

  @override
  Widget build(BuildContext context) {
    final short = CompanionReferenceTokens.isShortViewport(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF120E18).withValues(alpha: 0.86),
        border: Border.all(
          color: OraclyChrome.gold.withValues(alpha: 0.42),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(short ? 12 : 14, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CompanionCopy.introHello,
              style: ReadingTypography.sectionLabel(
                fontSize: short ? 12.5 : 13.5,
                color: OraclyChrome.goldLight,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                CompanionCopy.introBody,
                maxLines: short ? 3 : 5,
                overflow: TextOverflow.ellipsis,
                style: ReadingTypography.bodySmall(
                  color: OraclyChrome.cream.withValues(alpha: 0.88),
                ).copyWith(fontSize: short ? 11.5 : 12.2, height: 1.34),
              ),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: const Color(0xFF1A1224).withValues(alpha: 0.7),
                border: Border.all(
                  color: OraclyChrome.gold.withValues(alpha: 0.42),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  '☾  ${CompanionCopy.introBadge}',
                  style: ReadingTypography.micro(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
