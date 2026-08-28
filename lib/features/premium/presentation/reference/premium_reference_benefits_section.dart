/// Three to five real benefits — exclusive mark only where gated.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../models/premium_models.dart';
import '../../providers/premium_providers.dart';
import '../../services/premium_access.dart';
import '../../services/soul_mate_dev_access.dart';
import '../../services/soul_mate_navigation.dart';
import 'premium_reference_feature_row.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceBenefitsSection extends ConsumerWidget {
  const PremiumReferenceBenefitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final benefits = PremiumCatalogue.showcaseBenefits;
    return Column(
      children: [
        Text(
          PremiumCopy.benefitsSectionTitle,
          textAlign: TextAlign.center,
          style: ReadingTypography.sectionLabel(fontSize: 11).copyWith(
            letterSpacing: 2.2,
            color: PremiumReferenceTokens.champagne.withValues(alpha: 0.86),
          ),
        ),
        SizedBox(height: PremiumReferenceTokens.sectionLabelToContent),
        for (var i = 0; i < benefits.length; i++) ...[
          if (i > 0) SizedBox(height: PremiumReferenceTokens.benefitItemGap),
          _BenefitEntry(benefit: benefits[i], isPremium: isPremium),
        ],
      ],
    );
  }
}

class _BenefitEntry extends StatelessWidget {
  const _BenefitEntry({required this.benefit, required this.isPremium});

  final PremiumBenefit benefit;
  final bool isPremium;

  bool get _locked {
    if (!benefit.requiresPremium) return false;
    if (benefit.action == PremiumBenefitAction.soulMate &&
        SoulMateDevAccess.allowsTestAccess) {
      return false;
    }
    return !isPremium;
  }

  VoidCallback? _onTap(BuildContext context) {
    return switch (benefit.action) {
      PremiumBenefitAction.soulMate => () {
          if (_locked) {
            PremiumAccess.prompt(context);
            return;
          }
          SoulMateNavigation.open(context);
        },
      PremiumBenefitAction.coffee => () =>
          OraclyNavigationService.openCoffee(context),
      PremiumBenefitAction.palm => () =>
          OraclyNavigationService.openPalm(context),
      PremiumBenefitAction.discovery => () =>
          OraclyNavigationService.openDiscoveryJournal(context),
      PremiumBenefitAction.companion => () =>
          OraclyNavigationService.openChat(context),
      PremiumBenefitAction.journey => () {
          if (_locked) {
            PremiumAccess.prompt(context);
            return;
          }
          OraclyNavigationService.openChat(context);
        },
      PremiumBenefitAction.daily => () =>
          OraclyNavigationService.openDailyMessage(context),
      PremiumBenefitAction.depth ||
      PremiumBenefitAction.continuity ||
      PremiumBenefitAction.personalization ||
      PremiumBenefitAction.none =>
        null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PremiumReferenceFeatureRow(
      benefit: benefit,
      locked: _locked,
      highlighted: benefit.requiresPremium,
      onTap: _onTap(context),
    );
  }
}
