/// Coffee V2 temporary preview (Phase 2C2 §7/§8). The picked file is an
/// EPHEMERAL candidate here — it is never written into the submission
/// draft until "Bu fotoğrafı kullan" is tapped, so backing out always
/// preserves whatever confirmed asset previously existed for this slot.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/camera/oracly_capture_preview_actions.dart';
import '../controllers/coffee_v2_flow_controller.dart';
import '../../presentation/reference/coffee_gold_preview.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../copy/coffee_v2_copy.dart';

class CoffeeV2PreviewView extends StatelessWidget {
  const CoffeeV2PreviewView({super.key, required this.controller});

  final CoffeeV2FlowController controller;

  @override
  Widget build(BuildContext context) {
    final slot = controller.previewCandidateSlot;
    final candidate = controller.previewCandidate;
    if (slot == null || candidate == null) {
      // Defensive — stage computation only reaches here when both exist.
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.s16),
          Text(
            CoffeeV2Copy.titleFor(slot),
            textAlign: TextAlign.center,
            style: ReadingTypography.pageTitle(),
          ),
          SizedBox(height: AppSpacing.s16),
          AspectRatio(
            aspectRatio: 1,
            child: CoffeeGoldPreview(
              path: candidate.path,
              framed: true,
              hero: true,
              maxCacheWidth: 1280,
            ),
          ),
          SizedBox(height: AppSpacing.s24),
          OraclyCapturePreviewActions(
            useLabel: CoffeeV2Copy.previewUse,
            retakeLabel: CoffeeV2Copy.previewRetake,
            onUse: () => controller.confirmCandidate(),
            onRetake: controller.discardPreviewCandidate,
          ),
          SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }
}
