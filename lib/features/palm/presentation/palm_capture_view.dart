/// Photo capture / gold preview — chamber camera, retake, use photo.
library;

import 'package:flutter/material.dart';

import '../../../core/security/ai_error_sanitizer.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/camera/oracly_capture_kind.dart';
import '../../../shared/camera/oracly_capture_preview_actions.dart';
import '../../../shared/camera/oracly_chamber_camera.dart';
import '../../../shared/ui/oracly_permission_dialog.dart';
import '../controllers/palm_reading_controller.dart';
import '../copy/palm_copy.dart';
import 'palm_capture_hint.dart';
import 'palm_gold_preview.dart';
import 'palm_hand_choice.dart';
import 'palm_landing_actions.dart';
import 'palm_placement_guide.dart';
import 'palm_tokens.dart';

class PalmCaptureView extends StatelessWidget {
  const PalmCaptureView({
    super.key,
    required this.controller,
    required this.onAnalyze,
    this.busy = false,
  });

  final PalmReadingController controller;
  final VoidCallback onAnalyze;
  final bool busy;

  Future<void> _openChamber(BuildContext context) async {
    final allowed = await OraclyPermissionDialog.cameraPalm(context);
    if (allowed != true || !context.mounted) return;
    final path = await OraclyChamberCamera.open(
      context,
      kind: OraclyCaptureKind.palm,
    );
    if (!context.mounted || path == null) return;
    await controller.acceptCapturedPath(path);
  }

  @override
  Widget build(BuildContext context) {
    final image = controller.image;
    final error = controller.errorMessage;
    final quality = controller.qualityHint;
    final hint = error != null
        ? AiErrorSanitizer.guard(
            error,
            fallback: PalmCopy.analysisFailed,
          )
        : quality;
    final attention = hint != null && error == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          image == null ? PalmCopy.addPhotoTitle : PalmCopy.previewLabel,
          textAlign: TextAlign.center,
          style: ReadingTypography.sectionLabel(),
        ),
        SizedBox(height: PalmTokens.gap),
        PalmHandChoice(
          selected: controller.hand,
          onSelected: controller.selectHand,
        ),
        SizedBox(height: PalmTokens.gap),
        Expanded(
          child: image != null
              ? PalmGoldPreview(path: image.path, contain: true, soft: true)
              : const PalmPlacementGuide(),
        ),
        SizedBox(height: PalmTokens.gap),
        if (hint != null) ...[
          PalmCaptureHint(hint, attention: attention),
          SizedBox(height: PalmTokens.gap),
        ],
        if (image == null)
          PalmLandingActions(
            onCamera: controller.images.cameraAvailable
                ? () => _openChamber(context)
                : () {},
            onGallery: controller.pickGallery,
            cameraEnabled: controller.images.cameraAvailable,
          )
        else
          OraclyCapturePreviewActions(
            useLabel: PalmCopy.usePhotoLabel,
            retakeLabel: PalmCopy.retakeLabel,
            onUse: busy ? null : onAnalyze,
            onRetake: () => _openChamber(context),
            galleryLabel: PalmCopy.galleryLabel,
            onGallery: controller.pickGallery,
            hint: PalmCopy.previewCtaHint,
          ),
      ],
    );
  }
}
