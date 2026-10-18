/// Premium scroll body — hero, experiences, honest store or membership.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/domain/models/premium_plan.dart';
import '../../controllers/premium_status_controller.dart';
import 'premium_legal_disclosure.dart';
import 'premium_qa_preview.dart';
import 'premium_reference_cta_unavailable.dart';
import 'premium_reference_experiences_section.dart';
import 'premium_reference_gem_note.dart';
import 'premium_reference_hero_card.dart';
import 'premium_reference_links.dart';
import 'premium_reference_store_section.dart';
import 'premium_reference_tokens.dart';

class PremiumReferenceBody extends StatelessWidget {
  const PremiumReferenceBody({
    super.key,
    required this.status,
    required this.onPurchase,
    required this.onRestore,
    required this.onRetryStore,
    this.onStoreDiagnostics,
    this.preview = PremiumQaPreviewKind.none,
    this.plansAnchor,
  });

  final PremiumStatusController status;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onRetryStore;
  final VoidCallback? onStoreDiagnostics;
  final PremiumQaPreviewKind preview;
  final GlobalKey? plansAnchor;

  bool get _previewing => preview != PremiumQaPreviewKind.none;

  PremiumPlanKind? get _claim {
    if (_previewing) return null;
    if (status.isPremium) return status.activePlan;
    if (status.storeOffersPlans) return status.selectedPlan;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final showPlansJump = !_previewing
        ? !status.isPremium
        : preview == PremiumQaPreviewKind.plans;
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        PremiumReferenceTokens.screenHorizontal,
        PremiumReferenceTokens.headerToHero,
        PremiumReferenceTokens.screenHorizontal,
        AppLayout.scrollBottomInset(context) + AppSpacing.s16,
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
                if (_previewing) const PremiumQaPreviewBanner(),
                PremiumReferenceHeroCard(
                  active: status.isPremium && !_previewing,
                  onSeePlans: showPlansJump ? _jumpToPlans : null,
                ),
                SizedBox(height: PremiumReferenceTokens.heroToBenefits),
                PremiumReferenceExperiencesSection(
                  forceLocked: _previewing,
                  preview: preview,
                  onInspectPlans: showPlansJump ? _jumpToPlans : null,
                ),
                SizedBox(height: PremiumReferenceTokens.benefitsToPlans),
                const PremiumReferenceGemNote(),
                SizedBox(height: PremiumReferenceTokens.benefitsToPlans),
                KeyedSubtree(
                  key: plansAnchor,
                  child: _store(),
                ),
                if (status.loaded || _previewing) ...[
                  SizedBox(height: PremiumReferenceTokens.plansToCta),
                  PremiumLegalDisclosure(
                    selectedPlan: _claim ?? PremiumPlanKind.yearly,
                    namePeriod: _claim != null,
                    showRestoreHint: !status.isPremium && !_previewing,
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

  void _jumpToPlans() {
    final target = plansAnchor?.currentContext;
    if (target == null) return;
    final motion = MediaQuery.disableAnimationsOf(target);
    Scrollable.ensureVisible(
      target,
      duration: motion ? Duration.zero : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Widget _store() {
    if (preview == PremiumQaPreviewKind.plans) {
      return const PremiumQaPreviewPlans();
    }
    if (preview == PremiumQaPreviewKind.unavailable) {
      return const PremiumReferenceCtaUnavailable();
    }
    return PremiumReferenceStoreSection(
      status: status,
      onPurchase: onPurchase,
      onRestore: onRestore,
      onRetryStore: onRetryStore,
      onStoreDiagnostics: onStoreDiagnostics,
    );
  }
}
