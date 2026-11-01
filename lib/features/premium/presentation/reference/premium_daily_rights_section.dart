/// Freemium V1 — what Premium adds every day, stated against the free
/// plan: 2 + 2 readings, no wait, Fincan Haritası. Facts only; the
/// readings themselves are the same on both plans, and it says so.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../reading_access/copy/freemium_copy.dart';
import 'premium_reference_benefit_group.dart';
import 'premium_reference_tokens.dart';

class PremiumDailyRightsSection extends StatelessWidget {
  const PremiumDailyRightsSection({super.key, required this.active});

  /// A verified member: the rows read as "open", not as an offer.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return PremiumReferenceBenefitGroup(
      title: FreemiumCopy.premiumSectionTitle,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: OraclyChrome.cardRadius,
            border: Border.all(
              color: PremiumReferenceTokens.champagne.withValues(alpha: 0.32),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                OraclyChrome.deepNavy.withValues(alpha: 0.7),
                OraclyChrome.cardSurface.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Row(
                  icon: Icons.coffee_outlined,
                  title: FreemiumCopy.premiumCoffeeTitle,
                  body: FreemiumCopy.premiumDailyFreeBody,
                  active: active,
                ),
                _Row(
                  icon: Icons.back_hand_outlined,
                  title: FreemiumCopy.premiumPalmTitle,
                  body: FreemiumCopy.premiumDailyFreeBody,
                  active: active,
                ),
                _Row(
                  icon: Icons.bolt_outlined,
                  title: FreemiumCopy.premiumInstantTitle,
                  body: FreemiumCopy.premiumInstantBody,
                  active: active,
                ),
                _Row(
                  icon: Icons.place_outlined,
                  title: FreemiumCopy.premiumCupMapTitle,
                  body: FreemiumCopy.premiumCupMapBody,
                  active: active,
                  last: true,
                ),
                SizedBox(height: AppSpacing.s12),
                Text(
                  active
                      ? FreemiumCopy.premiumActiveNote
                      : FreemiumCopy.premiumSameCare,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.footnote(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.body,
    required this.active,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: last
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: OraclyChrome.gold.withValues(alpha: 0.12),
                  ),
                ),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OraclyChrome.midnight.withValues(alpha: 0.6),
                  border: Border.all(
                    color: OraclyChrome.gold.withValues(
                      alpha: active
                          ? OraclyChrome.borderEmphasis
                          : OraclyChrome.borderHairline,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: OraclyChrome.gold.withValues(alpha: active ? 1 : 0.8),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ReadingTypography.bodyCore(
                      color: OraclyChrome.cream.withValues(alpha: 0.96),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: ReadingTypography.secondary(
                      color: OraclyChrome.cream.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 6),
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: OraclyChrome.gold.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
