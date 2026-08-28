/// Premium scroll body — hero, benefits, gems, honest CTA.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../controllers/premium_status_controller.dart';
import '../../models/premium_entitlement_state.dart';
import 'premium_reference_benefits_section.dart';
import 'premium_reference_cta.dart';
import 'premium_reference_cta_unavailable.dart';
import 'premium_reference_experiences_section.dart';
import 'premium_reference_gem_note.dart';
import 'premium_reference_hero_card.dart';
import 'premium_reference_links.dart';
import 'premium_reference_plans_section.dart';
import 'premium_reference_tokens.dart';
import 'premium_reference_value_section.dart';

class PremiumReferenceBody extends StatelessWidget {
  const PremiumReferenceBody({
    super.key,
    required this.status,
    required this.onPurchase,
    required this.onRestore,
    required this.onRetryStore,
  });

  final PremiumStatusController status;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onRetryStore;

  @override
  Widget build(BuildContext context) {
    final showStore = status.purchaseConfigured && !status.isPremium;
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
                if (!status.loaded)
                  Text(
                    PremiumCopy.loadingBody,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.secondary(
                      color: OraclyChrome.cream.withValues(alpha: 0.7),
                    ),
                  )
                else if (status.entitlement == PremiumEntitlementState.error) ...[
                  Text(
                    status.entitlementMessage ?? PremiumCopy.purchaseFailed,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.body(
                      color: OraclyChrome.cream.withValues(alpha: 0.86),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OraclyPressable(
                    onTap: onRetryStore,
                    child: Text(
                      PremiumCopy.errorRetry,
                      textAlign: TextAlign.center,
                      style: ReadingTypography.metadata(
                        color: OraclyChrome.goldLight.withValues(alpha: 0.8),
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ] else if (showStore) ...[
                  PremiumReferencePlansSection(
                    plans: status.plans,
                    selected: status.selectedPlan,
                    onSelected: status.selectPlan,
                  ),
                  SizedBox(height: PremiumReferenceTokens.plansToCta),
                  PremiumReferenceCta(
                    isPremium: false,
                    busy: status.busy,
                    purchaseConfigured: true,
                    onActivate: onPurchase,
                    onRestore: onRestore,
                  ),
                ] else if (status.isPremium)
                  const PremiumReferenceCta(isPremium: true)
                else if (status.entitlement ==
                    PremiumEntitlementState.unverified) ...[
                  Text(
                    status.entitlementMessage ??
                        PremiumCopy.entitlementUnverified,
                    textAlign: TextAlign.center,
                    style: ReadingTypography.body(
                      color: OraclyChrome.cream.withValues(alpha: 0.86),
                    ),
                  ),
                  SizedBox(height: PremiumReferenceTokens.plansToCta),
                  if (status.purchaseConfigured)
                    PremiumReferenceCta(
                      isPremium: false,
                      busy: status.busy,
                      purchaseConfigured: true,
                      onActivate: onPurchase,
                      onRestore: onRestore,
                    )
                  else
                    PremiumReferenceCtaUnavailable(onRetry: onRetryStore),
                ] else
                  PremiumReferenceCtaUnavailable(onRetry: onRetryStore),
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
