/// OR-specific Premium paywall — chamber language, commerce entitlement.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/domain/models/premium_plan.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../premium/models/premium_entitlement_state.dart';
import '../../../premium/presentation/reference/premium_reference_cta.dart';
import '../../../premium/presentation/reference/premium_reference_plans_section.dart';
import '../../copy/companion_copy.dart';
import 'companion_reference_or_entitlement_banner.dart';
import 'companion_reference_or_paywall_hero.dart';
import 'companion_reference_or_paywall_pillars.dart';

class CompanionReferenceOrPaywall extends StatelessWidget {
  const CompanionReferenceOrPaywall({
    super.key,
    required this.entitlement,
    required this.purchaseConfigured,
    required this.onPurchase,
    required this.onRestore,
    this.entitlementMessage,
    this.compact = false,
    this.showHero = true,
    this.plans = const [],
    this.selectedPlan = PremiumPlanKind.yearly,
    this.onSelectPlan,
    this.premiumUnlocked,
  });

  final PremiumEntitlementState entitlement;
  final bool purchaseConfigured;
  final String? entitlementMessage;
  final bool compact;
  final bool showHero;
  final List<PremiumPlanModel> plans;
  final PremiumPlanKind selectedPlan;
  final ValueChanged<PremiumPlanKind>? onSelectPlan;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  /// Commerce entitlement OR an active reviewer grant. Defaults to
  /// [entitlement]'s own commerce-only flag when not supplied, so existing
  /// callers keep their exact prior behavior.
  final bool? premiumUnlocked;

  @override
  Widget build(BuildContext context) {
    final active = premiumUnlocked ?? entitlement.allowsPremiumFeatures;
    final showPlans = purchaseConfigured &&
        !active &&
        !entitlement.isTransient &&
        plans.isNotEmpty &&
        onSelectPlan != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 0, 0, compact ? 8 : 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHero) ...[
            const CompanionReferenceOrPaywallHero(),
            SizedBox(height: AppSpacing.s20),
          ] else ...[
            Text(
              CompanionCopy.orPaywallTitle,
              textAlign: TextAlign.center,
              style: ReadingTypography.sectionTitle(
                color: OraclyChrome.goldLight.withValues(alpha: 0.92),
              ),
            ),
            SizedBox(height: AppSpacing.s8),
            Text(
              CompanionCopy.orPaywallLead,
              textAlign: TextAlign.center,
              style: ReadingTypography.bodySmall(
                color: OraclyChrome.cream.withValues(alpha: 0.78),
              ),
            ),
            SizedBox(height: AppSpacing.s16),
          ],
          const CompanionReferenceOrPaywallPillars(),
          SizedBox(height: AppSpacing.s8),
          Text(
            CompanionCopy.orPaywallHonesty,
            textAlign: TextAlign.center,
            style: ReadingTypography.bodySmall(
              color: OraclyChrome.cream.withValues(alpha: 0.58),
            ),
          ),
          SizedBox(height: AppSpacing.s16),
          CompanionReferenceOrEntitlementBanner(
            state: entitlement,
            message: entitlementMessage,
          ),
          if (showPlans) ...[
            PremiumReferencePlansSection(
              plans: plans,
              selected: selectedPlan,
              onSelected: onSelectPlan!,
            ),
            SizedBox(height: AppSpacing.s16),
          ],
          PremiumReferenceCta(
            isPremium: active,
            busy: entitlement.isTransient,
            purchaseConfigured: purchaseConfigured,
            joinLabel: CompanionCopy.orPaywallCta,
            onActivate: entitlement.canStartPurchase ? onPurchase : null,
            onRestore: entitlement.canStartRestore ? onRestore : null,
          ),
          if (!active) ...[
            SizedBox(height: AppSpacing.s8),
            Text(
              CompanionCopy.orPremiumAside,
              textAlign: TextAlign.center,
              style: ReadingTypography.bodySmall(
                color: OraclyChrome.goldLight.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
