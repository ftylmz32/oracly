/// Coffee V3 intro — what the four photos are for. Calm, no AI/vision
/// language; same layout as the Coffee V2 intro.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../copy/coffee_v3_copy.dart';

class CoffeeV3IntroView extends StatelessWidget {
  const CoffeeV3IntroView({super.key, required this.onStart});

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
            CoffeeV3Copy.introTitle,
            textAlign: TextAlign.center,
            style: ReadingTypography.display(),
          ),
          SizedBox(height: AppSpacing.s16),
          Text(
            CoffeeV3Copy.introBody,
            textAlign: TextAlign.center,
            style: ReadingTypography.secondary(),
          ),
          SizedBox(height: AppSpacing.s24),
          for (final label in const [
            CoffeeV3Copy.introSummaryHandleFar,
            CoffeeV3Copy.introSummaryTurnA,
            CoffeeV3Copy.introSummaryTurnB,
            CoffeeV3Copy.introSummarySaucer,
          ]) ...[
            Text(
              label,
              textAlign: TextAlign.center,
              style: ReadingTypography.footnote(),
            ),
            SizedBox(height: AppSpacing.s8),
          ],
          SizedBox(height: AppSpacing.s24),
          OraclyGoldButton(
            label: CoffeeV3Copy.introCta,
            expanded: true,
            onPressed: onStart,
          ),
          SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }
}
