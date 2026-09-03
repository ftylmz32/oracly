/// Store-policy disclosure under Premium CTA — recurring vs lifetime clarity.
library;

import 'package:flutter/material.dart';

import '../../../../core/domain/models/premium_plan.dart';
import '../../../../core/legal/legal_copy.dart';
import '../../../../core/legal/legal_document_kind.dart';
import '../../../../core/legal/legal_link_actions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_pressable.dart';

class PremiumLegalDisclosure extends StatelessWidget {
  const PremiumLegalDisclosure({
    super.key,
    required this.selectedPlan,
    this.showRestoreHint = true,
  });

  final PremiumPlanKind selectedPlan;
  final bool showRestoreHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LegalCopy.planDisclosure(selectedPlan),
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: AppColors.textSecondary.withValues(alpha: 0.88),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          LegalCopy.storeBillingNote,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: AppColors.textHint.withValues(alpha: 0.9),
          ),
        ),
        if (selectedPlan != PremiumPlanKind.lifetime) ...[
          const SizedBox(height: 6),
          Text(
            LegalCopy.cancelNote,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(
              color: AppColors.textHint.withValues(alpha: 0.9),
            ),
          ),
        ],
        if (showRestoreHint) ...[
          const SizedBox(height: 6),
          Text(
            LegalCopy.restoreNote,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(
              color: AppColors.textHint.withValues(alpha: 0.9),
            ),
          ),
        ],
        const SizedBox(height: 14),
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
    );
  }
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
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.goldLight.withValues(alpha: 0.86),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}