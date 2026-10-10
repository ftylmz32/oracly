/// Coffee V3 step capture. Reuses the exact chamber camera / permission
/// dialog / gallery picker mechanics of Coffee V2 — no second picker or
/// permission stack. The cup guide is shown for the three cup views only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/camera/oracly_capture_kind.dart';
import '../../../../shared/camera/oracly_chamber_camera.dart';
import '../../../../shared/ui/oracly_permission_dialog.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_quiet_link.dart';
import '../../models/coffee_image_pick.dart';
import '../../presentation/reference/coffee_capture_cup_guide.dart';
import '../../presentation/reference/coffee_capture_hint.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../../providers/coffee_providers.dart';
import '../../services/coffee_image_pick_exception.dart';
import '../controllers/coffee_v3_flow_controller.dart';
import '../copy/coffee_v3_copy.dart';
import '../models/coffee_v3_photo_slot.dart';

class CoffeeV3StepView extends ConsumerStatefulWidget {
  const CoffeeV3StepView({
    super.key,
    required this.controller,
    required this.slot,
  });

  final CoffeeV3FlowController controller;
  final CoffeeV3PhotoSlot slot;

  @override
  ConsumerState<CoffeeV3StepView> createState() => _CoffeeV3StepViewState();
}

class _CoffeeV3StepViewState extends ConsumerState<CoffeeV3StepView> {
  String? _pickerError;

  Future<void> _takePhoto() async {
    setState(() => _pickerError = null);
    final confirmed = await OraclyPermissionDialog.cameraCoffee(context);
    if (confirmed != true || !mounted) return;
    final path = await OraclyChamberCamera.open(
      context,
      kind: OraclyCaptureKind.coffee,
    );
    if (path == null || !mounted) return;
    widget.controller.setPreviewCandidate(
      widget.slot,
      CoffeeImagePick(path: path),
    );
  }

  Future<void> _pickGallery() async {
    setState(() => _pickerError = null);
    try {
      final picked =
          await ref.read(coffeeImageInputProvider).pickFromGallery();
      if (picked == null || !mounted) return;
      widget.controller.setPreviewCandidate(widget.slot, picked);
    } on CoffeeImagePickException catch (e) {
      if (mounted) setState(() => _pickerError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final slot = widget.slot;
    final hint = _pickerError ??
        (controller.lastSelectionFailure != null
            ? CoffeeV3Copy.invalidPhotoMessage
            : null) ??
        (controller.lastDuplicateOf != null
            ? CoffeeV3Copy.duplicateMessage
            : null);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.s24),
          Text(
            CoffeeV3Copy.progressLabel(CoffeeV3Copy.stepNumber(slot)),
            textAlign: TextAlign.center,
            style: ReadingTypography.eyebrow(),
          ),
          SizedBox(height: AppSpacing.s12),
          Text(
            CoffeeV3Copy.titleFor(slot),
            textAlign: TextAlign.center,
            style: ReadingTypography.pageTitle(),
          ),
          SizedBox(height: AppSpacing.s12),
          Text(
            CoffeeV3Copy.instructionFor(slot),
            textAlign: TextAlign.center,
            style: ReadingTypography.secondary(),
          ),
          SizedBox(height: AppSpacing.s24),
          if (slot != CoffeeV3PhotoSlot.saucer)
            const SizedBox(height: 160, child: CoffeeCaptureCupGuide()),
          if (hint != null) ...[
            SizedBox(height: AppSpacing.s16),
            CoffeeCaptureHint(hint, attention: true),
          ],
          SizedBox(height: AppSpacing.s24),
          OraclyGoldButton(
            label: CoffeeV3Copy.actionTakePhoto,
            expanded: true,
            onPressed: _takePhoto,
          ),
          SizedBox(height: AppSpacing.s8),
          OraclyQuietLink(
            label: CoffeeV3Copy.actionPickGallery,
            onTap: _pickGallery,
          ),
          if (controller.replacingSlot != null) ...[
            SizedBox(height: AppSpacing.s8),
            OraclyQuietLink(
              label: CoffeeV3Copy.actionBack,
              onTap: controller.cancelReplacing,
            ),
          ],
          SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }
}
