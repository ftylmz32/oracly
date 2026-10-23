/// Store-policy disclosure under Premium CTA — recurring vs lifetime clarity.
library;

import 'package:flutter/material.dart';

import '../../../../core/domain/models/premium_plan.dart';
import '../../../../core/legal/legal_copy.dart';
import '../../../../core/legal/legal_document_kind.dart';
import '../../../../core/legal/legal_link_actions.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class PremiumLegalDisclosure extends StatelessWidget {
  const PremiumLegalDisclosure({
    super.key,
    required this.selectedPlan,
    this.namePeriod = true,
    this.showRestoreHint = true,
  });

  final PremiumPlanKind selectedPlan;

  /// False when no store plan or active plan has been verified.
  final bool namePeriod;
  final bool showRestoreHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0A14).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: OraclyChrome.goldLight.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        if (namePeriod)
          Text(
            LegalCopy.planDisclosure(selectedPlan),
            textAlign: TextAlign.start,
            style: _disclosureStyle(),
          ),
        if (namePeriod) const SizedBox(height: 8),
        Text(
          LegalCopy.storeBillingNote,
          textAlign: TextAlign.start,
          style: _disclosureStyle(),
        ),
        if (namePeriod && selectedPlan != PremiumPlanKind.lifetime) ...[
          const SizedBox(height: 6),
          Text(
            LegalCopy.cancelNote,
            textAlign: TextAlign.start,
            style: _disclosureStyle(),
          ),
        ],
        if (showRestoreHint) ...[
          const SizedBox(height: 6),
          Text(
            LegalCopy.restoreNote,
            textAlign: TextAlign.start,
            style: _disclosureStyle(),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            _Link(
              label: LegalCopy.privacyPolicy,
              onTap: () => LegalLinkActions.openDocument(
                context,
                LegalDocumentKind.privacyPolicy,
              ),
            ),
            _Dot(),
            _Link(
              label: LegalCopy.termsOfUse,
              onTap: () => LegalLinkActions.openDocument(
                context,
                LegalDocumentKind.termsOfUse,
              ),
            ),
            _Dot(),
            _Link(
              label: LegalCopy.manageSubscription,
              onTap: () => LegalLinkActions.openManageSubscription(context),
            ),
          ],
        ),
        ],
      ),
    );
  }

  TextStyle _disclosureStyle() => ReadingTypography.metadata(
    color: OraclyChrome.cream.withValues(alpha: 0.87),
  ).copyWith(
    fontSize: 13.5,
    height: 1.42,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w400,
  );
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '·',
      style: AppTextStyles.caption.copyWith(
        color: AppColors.gold.withValues(alpha: 0.55),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OraclyPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.goldLight.withValues(alpha: 0.86),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}