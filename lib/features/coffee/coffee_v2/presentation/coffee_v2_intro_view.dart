/// Coffee V2 intro — locked copy (Phase 2C2 §3). No AI/vision/pipeline
/// language; a calm, warm explanation of what the three photos are for.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../copy/coffee_v2_copy.dart';

class CoffeeV2IntroView extends StatelessWidget {
  const CoffeeV2IntroView({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.s32),
          Text(
            CoffeeV2Copy.introTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.display(),
          ),
          SizedBox(height: AppSpacing.s16),
          Text(
            CoffeeV2Copy.introBody,
            textAlign: TextAlign.center,
            style: ReadingTypography.secondary(),
          ),
          SizedBox(height: AppSpacing.s24),
          _IntroStep(CoffeeV2Copy.introSummaryPrimary),
          SizedBox(height: AppSpacing.s8),
          _IntroStep(CoffeeV2Copy.introSummarySecondary),
          SizedBox(height: AppSpacing.s8),
          _IntroStep(CoffeeV2Copy.introSummarySaucer),
          SizedBox(height: AppSpacing.s32),
          OraclyGoldButton(
            label: CoffeeV2Copy.introCta,
            expanded: true,
            onPressed: onStart,
          ),
          SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: ReadingTypography.footnote(),
    );
  }
}
