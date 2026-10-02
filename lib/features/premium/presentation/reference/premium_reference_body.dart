/// Premium scroll body — hero, benefits, gems, honest CTA.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../controllers/premium_status_controller.dart';
import 'premium_reference_benefits_section.dart';
import 'premium_reference_experiences_section.dart';
import 'premium_reference_gem_note.dart';
import 'premium_reference_hero_card.dart';
import 'premium_legal_disclosure.dart';
import 'premium_reference_links.dart';
import 'premium_reference_store_section.dart';
import 'premium_reference_tokens.dart';
import 'premium_reference_value_section.dart';

class PremiumReferenceBody extends StatelessWidget {
  const PremiumReferenceBody({
    super.key,
    required this.status,
    required this.onPurchase,
    required this.onRestore,
    required this.onRetryStore,
    this.onStoreDiagnostics,
  });

  final PremiumStatusController status;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onRetryStore;
  final VoidCallback? onStoreDiagnostics;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        PremiumReferenceTokens.screenHorizontal,
        PremiumReferenceTokens.headerToHero,
        PremiumReferenceTokens.screenHorizontal,
        AppLayout.scrollBottomInset(context),
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumReferenceHeroCard(active: status.isPremium),
                SizedBox(height: PremiumReferenceTokens.heroToBenefits),
                const PremiumReferenceValueSection(),
                SizedBox(height: PremiumReferenceTokens.heroToBenefits),
                const PremiumReferenceExperiencesSection(),
                SizedBox(height: PremiumReferenceTokens.heroToBenefits),
                const PremiumReferenceBenefitsSection(),
                SizedBox(height: PremiumReferenceTokens.benefitsToPlans),
                const PremiumReferenceGemNote(),
                SizedBox(height: PremiumReferenceTokens.benefitsToPlans),
                PremiumReferenceStoreSection(
                  status: status,
                  onPurchase: onPurchase,
                  onRestore: onRestore,
                  onRetryStore: onRetryStore,
                  onStoreDiagnostics: onStoreDiagnostics,
                ),
                if (status.loaded) ...[
                  SizedBox(height: PremiumReferenceTokens.plansToCta),
                  PremiumLegalDisclosure(
                    selectedPlan: status.selectedPlan,
                    showRestoreHint: !status.isPremium,
                  ),
                ],
                SizedBox(height: PremiumReferenceTokens.ctaToLinks),
                const PremiumReferenceLinks(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
