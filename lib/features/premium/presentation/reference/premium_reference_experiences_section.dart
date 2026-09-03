/// Three concrete Premium experiences — Soulmate, OR, Journey depth.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../models/premium_models.dart';
import '../../providers/premium_providers.dart';
import '../../services/premium_access.dart';
import '../../services/soul_mate_dev_access.dart';
import '../../services/soul_mate_navigation.dart';
import 'premium_reference_benefit_group.dart';
import 'premium_reference_feature_row.dart';

class PremiumReferenceExperiencesSection extends ConsumerWidget {
  const PremiumReferenceExperiencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final benefits = PremiumCatalogue.concretePremiumExperiences;
    return PremiumReferenceBenefitGroup(
      title: PremiumCopy.experiencesSectionTitle,
      children: [
        for (var i = 0; i < benefits.length; i++)
          _ExperienceEntry(benefit: benefits[i], isPremium: isPremium),
      ],
    );
  }
}

class _ExperienceEntry extends StatelessWidget {
  const _ExperienceEntry({required this.benefit, required this.isPremium});

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
      PremiumBenefitAction.companion => () {
          if (_locked) {
            PremiumAccess.prompt(context);
            return;
          }
          OraclyNavigationService.openChat(context);
        },
      PremiumBenefitAction.journey => () {
          if (_locked) {
            PremiumAccess.prompt(context);
            return;
          }
          OraclyNavigationService.openChat(context);
        },
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PremiumReferenceFeatureRow(
      benefit: benefit,
      locked: _locked,
      highlighted: true,
      onTap: _onTap(context),
    );
  }
}