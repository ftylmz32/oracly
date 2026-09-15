/// Coffee V2 staging-in-progress / retryable-staging-error state (Phase
/// 2C2 §16). No technical language (operationId/HTTP/stage/slot names
/// never surface here) — a calm transient state, or a retry CTA that
/// always continues the SAME operationId (Phase 2C1's own guarantee).
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../controllers/coffee_v2_flow_controller.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../copy/coffee_v2_copy.dart';

class CoffeeV2ActiveStagingView extends StatelessWidget {
  const CoffeeV2ActiveStagingView({super.key, required this.controller});

  final CoffeeV2FlowController controller;

  @override
  Widget build(BuildContext context) {
    final retryable = controller.stagingRetryable;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!retryable)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: CircularProgressIndicator(),
              ),
            Text(
              retryable
                  ? CoffeeV2Copy.stagingConnectionLost
                  : CoffeeV2Copy.stagingInProgress,
              textAlign: TextAlign.center,
              style: ReadingTypography.secondary(),
            ),
            if (retryable) ...[
              SizedBox(height: AppSpacing.s24),
              OraclyGoldButton(
                label: CoffeeV2Copy.stagingRetry,
                onPressed: controller.retryStaging,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
