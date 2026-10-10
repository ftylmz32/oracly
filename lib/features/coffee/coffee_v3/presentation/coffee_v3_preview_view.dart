/// Coffee V3 temporary preview. The picked file is an EPHEMERAL candidate
/// until "Bu fotoğrafı kullan"; backing out never touches the slot's
/// previously confirmed photo.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/camera/oracly_capture_preview_actions.dart';
import '../../presentation/reference/coffee_gold_preview.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../controllers/coffee_v3_flow_controller.dart';
import '../copy/coffee_v3_copy.dart';

class CoffeeV3PreviewView extends StatelessWidget {
  const CoffeeV3PreviewView({super.key, required this.controller});

  final CoffeeV3FlowController controller;

  @override
  Widget build(BuildContext context) {
    final slot = controller.previewCandidateSlot;
    final candidate = controller.previewCandidate;
    if (slot == null || candidate == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.s16),
          Text(
            CoffeeV3Copy.titleFor(slot),
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
            useLabel: CoffeeV3Copy.previewUse,
            retakeLabel: CoffeeV3Copy.previewRetake,
            onUse: () => controller.confirmCandidate(),
            onRetake: controller.discardPreviewCandidate,
          ),
          SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }
}
