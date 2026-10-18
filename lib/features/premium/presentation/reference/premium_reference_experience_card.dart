/// One Premium experience — a real plate, a concrete sentence, an honest lock.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_asset_image.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../models/premium_models.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceExperienceCard extends StatelessWidget {
  const PremiumReferenceExperienceCard({
    super.key,
    required this.benefit,
    required this.locked,
    this.onTap,
  });

  final PremiumBenefit benefit;
  final bool locked;
  final VoidCallback? onTap;

  /// Native frame of the approved cover — full plate, no stretch.
  static const soulMateAspect = 1440 / 606;

  static String? plateFor(PremiumBenefitAction action) => switch (action) {
        PremiumBenefitAction.soulMate => AppAssets.premiumSoulMateCover,
        PremiumBenefitAction.companion => AppAssets.encounterJournal,
        PremiumBenefitAction.journey => AppAssets.profileJournalHero,
        _ => null,
      };

  static double aspectFor(PremiumBenefitAction action) =>
      action == PremiumBenefitAction.soulMate ? soulMateAspect : 16 / 7;

  static Alignment alignmentFor(PremiumBenefitAction action) => switch (action) {
        PremiumBenefitAction.companion => const Alignment(0, -0.72),
        PremiumBenefitAction.journey => const Alignment(0, 0.15),
        _ => Alignment.center,
      };

  @override
  Widget build(BuildContext context) {
    final plate = plateFor(benefit.action);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.cardRadius,
        border: Border.all(
          color: PremiumReferenceTokens.champagne.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: OraclyChrome.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (plate != null)
              AspectRatio(
                aspectRatio: aspectFor(benefit.action),
                child: OraclyAssetImage(
                  assetPath: plate,
                  fit: BoxFit.cover,
                  alignment: alignmentFor(benefit.action),
                  filterQuality: FilterQuality.high,
                  fallback: const ColoredBox(color: PremiumReferenceTokens.ink),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _copy()),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      locked
                          ? Icons.lock_outline_rounded
                          : Icons.chevron_right_rounded,
                      size: 18,
                      color: PremiumReferenceTokens.champagne.withValues(
                        alpha: locked ? 0.7 : 0.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: benefit.title,
      child: OraclyPressable(onTap: onTap, child: card),
    );
  }

  Widget _copy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          benefit.title,
          softWrap: true,
          style: ReadingTypography.bodyCore(
            color: OraclyChrome.cream.withValues(alpha: 0.96),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          benefit.description,
          softWrap: true,
          style: ReadingTypography.secondary(
            color: OraclyChrome.cream.withValues(alpha: 0.74),
          ),
        ),
      ],
    );
  }
}
