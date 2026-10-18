/// Three concrete Premium experiences — Soulmate, OR, Journey depth.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/navigation/oracly_navigation_service.dart';
import '../../../companion/services/companion_or_conversation_access.dart';
import '../../models/premium_models.dart';
import '../../providers/premium_providers.dart';
import 'premium_entry_sheet.dart';
import 'premium_qa_preview.dart';
import '../../services/soul_mate_dev_access.dart';
import '../../services/soul_mate_navigation.dart';
import 'premium_reference_benefit_group.dart';
import 'premium_reference_experience_card.dart';

class PremiumReferenceExperiencesSection extends ConsumerWidget {
  const PremiumReferenceExperiencesSection({
    super.key,
    this.forceLocked = false,
    this.preview = PremiumQaPreviewKind.none,
    this.onInspectPlans,
  });

  /// Debug preview of a non-member. Never set from a release path.
  final bool forceLocked;
  final PremiumQaPreviewKind preview;

  /// Scrolls to the plans on this page. The sheet does not start a purchase.
  final VoidCallback? onInspectPlans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium =
        !forceLocked && ref.watch(premiumStatusProvider).isPremium;
    final benefits = PremiumCatalogue.concretePremiumExperiences;
    return PremiumReferenceBenefitGroup(
      title: PremiumCopy.experiencesSectionTitle,
      children: [
        for (var i = 0; i < benefits.length; i++)
          _ExperienceEntry(
            benefit: benefits[i],
            isPremium: isPremium,
            preview: preview,
            onInspectPlans: onInspectPlans,
          ),
      ],
    );
  }
}

class _ExperienceEntry extends StatelessWidget {
  const _ExperienceEntry({
    required this.benefit,
    required this.isPremium,
    this.preview = PremiumQaPreviewKind.none,
    this.onInspectPlans,
  });

  final PremiumBenefit benefit;
  final bool isPremium;
  final PremiumQaPreviewKind preview;
  final VoidCallback? onInspectPlans;

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
            _openSheet(context, PremiumEntryFocus.soulMate);
            return;
          }
          SoulMateNavigation.open(context);
        },
      PremiumBenefitAction.companion => () {
          if (_locked) {
            CompanionOrConversationAccess.showGate(context);
            return;
          }
          OraclyNavigationService.openChat(context);
        },
      PremiumBenefitAction.journey => () {
          if (_locked) {
            _openSheet(context, PremiumEntryFocus.journey);
            return;
          }
          OraclyNavigationService.openHome(context);
        },
      _ => null,
    };
  }

  void _openSheet(BuildContext context, PremiumEntryFocus focus) {
    PremiumEntrySheet.show(
      context,
      focus: focus,
      alreadyHere: true,
      previewClosed: preview == PremiumQaPreviewKind.unavailable,
      previewPlans: preview == PremiumQaPreviewKind.plans,
    ).then((intent) {
      if (intent == PremiumEntryIntent.plans) onInspectPlans?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumReferenceExperienceCard(
      benefit: benefit,
      locked: _locked,
      onTap: _onTap(context),
    );
  }
}