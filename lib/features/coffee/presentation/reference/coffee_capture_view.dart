/// Selected cup is the hero. Use photo / retake — never a naked OS camera.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/security/ai_error_sanitizer.dart';
import '../../../../shared/camera/oracly_capture_kind.dart';
import '../../../../shared/camera/oracly_capture_preview_actions.dart';
import '../../../../shared/camera/oracly_chamber_camera.dart';
import '../../../../shared/ui/oracly_permission_dialog.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../controllers/coffee_reading_controller.dart';
import '../../copy/coffee_copy.dart';
import 'coffee_capture_cup_guide.dart';
import 'coffee_capture_guide_copy.dart';
import 'coffee_capture_hint.dart';
import 'coffee_gold_preview.dart';
import 'coffee_quiet_link.dart';
import 'coffee_reference_tokens.dart';

class CoffeeCaptureView extends StatelessWidget {
  const CoffeeCaptureView({
    super.key,
    required this.controller,
    required this.onAnalyze,
    this.busy = false,
  });

  final CoffeeReadingController controller;
  final VoidCallback onAnalyze;
  final bool busy;

  Future<void> _openChamber(BuildContext context) async {
    final allowed = await OraclyPermissionDialog.cameraCoffee(context);
    if (allowed != true || !context.mounted) return;
    final path = await OraclyChamberCamera.open(
      context,
      kind: OraclyCaptureKind.coffee,
    );
    if (!context.mounted || path == null) return;
    await controller.acceptCapturedPath(path);
  }

  @override
  Widget build(BuildContext context) {
    final image = controller.image;
    final hint = controller.errorMessage != null
        ? AiErrorSanitizer.guard(
            controller.errorMessage,
            fallback: CoffeeCopy.analysisFailed,
          )
        : controller.qualityHint;
    final attention = hint != null && controller.errorMessage == null;

    if (image != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: CoffeeReferenceTokens.screenHorizontal,
              ),
              child: CoffeeGoldPreview(
                path: image.path,
                contain: true,
                framed: true,
                attention: attention,
                hero: true,
              ),
            ),
          ),
          SizedBox(height: CoffeeReferenceTokens.gap),
          if (hint != null) CoffeeCaptureHint(hint, attention: attention),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: CoffeeReferenceTokens.screenHorizontal,
            ),
            child: OraclyCapturePreviewActions(
              useLabel: CoffeeCopy.usePhotoLabel,
              retakeLabel: CoffeeCopy.retakeLabel,
              onUse: busy ? null : onAnalyze,
              onRetake: () => _openChamber(context),
              galleryLabel: CoffeeCopy.galleryLabel,
              onGallery: controller.pickGallery,
              hint: CoffeeCopy.previewCtaHint,
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CoffeeCaptureGuideHeader(),
          const SizedBox(height: AppSpacing.s12),
          const CoffeeCaptureCupGuide(),
          const SizedBox(height: AppSpacing.s12),
          const CoffeeCaptureGuideHelper(),
          const SizedBox(height: AppSpacing.s8),
          const CoffeeCaptureGuideTips(),
          if (hint != null) ...[
            SizedBox(height: CoffeeReferenceTokens.gap),
            CoffeeCaptureHint(hint, attention: attention, edgeInset: false),
          ],
          const SizedBox(height: AppSpacing.s16),
          OraclyGoldButton(
            label: CoffeeCopy.photoCta,
            icon: Icons.photo_camera_outlined,
            expanded: true,
            onPressed: controller.images.cameraAvailable
                ? () => _openChamber(context)
                : null,
          ),
          SizedBox(height: CoffeeReferenceTokens.gap),
          CoffeeQuietLink(
            label: CoffeeCopy.galleryLabel,
            onTap: controller.pickGallery,
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
      ),
    );
  }
}
