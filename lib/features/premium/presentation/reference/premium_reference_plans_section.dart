/// Reference premium plan selector cards.
library;

import 'package:flutter/material.dart';

import '../../../../core/copy/premium_copy.dart';
import '../../../../core/domain/models/premium_plan.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/oracly_signature_motifs.dart';
import 'premium_reference_plan_card.dart';
import 'premium_reference_tokens.dart';

class PremiumReferencePlansSection extends StatelessWidget {
  const PremiumReferencePlansSection({
    super.key,
    required this.plans,
    required this.selected,
    required this.onSelected,
  });

  final List<PremiumPlanModel> plans;
  final PremiumPlanKind selected;
  final ValueChanged<PremiumPlanKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          PremiumCopy.plansSectionTitle,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.gold.withValues(alpha: 0.88),
            letterSpacing: 2.2,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const OraclySignatureDivider(compact: true),
        SizedBox(height: PremiumReferenceTokens.sectionLabelToContent),
        for (var i = 0; i < plans.length; i++) ...[
          if (i > 0) SizedBox(height: PremiumReferenceTokens.planItemGap),
          PremiumReferencePlanCard(
            plan: plans[i],
            selected: plans[i].kind == selected,
            onTap: () => onSelected(plans[i].kind),
          ),
        ],
      ],
    );
  }
}
