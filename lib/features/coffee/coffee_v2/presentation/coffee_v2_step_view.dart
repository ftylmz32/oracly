/// Coffee V2 step capture screen (Phase 2C2 §4-§6). Reuses the exact same
/// chamber camera / permission dialog / gallery picker mechanics legacy
/// Coffee already uses — no second picker/permission stack.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/camera/oracly_capture_kind.dart';
import '../../../../shared/camera/oracly_chamber_camera.dart';
import '../../../../shared/widgets/oracly_gold_button.dart';
import '../../../../shared/widgets/oracly_quiet_link.dart';
import '../../../../shared/ui/oracly_permission_dialog.dart';
import '../controllers/coffee_v2_flow_controller.dart';
import '../../models/coffee_image_pick.dart';
import '../../presentation/reference/coffee_capture_cup_guide.dart';
import '../../presentation/reference/coffee_capture_hint.dart';
import '../../presentation/reference/coffee_reference_tokens.dart';
import '../../providers/coffee_providers.dart';
import '../../services/coffee_image_pick_exception.dart';
import '../copy/coffee_v2_copy.dart';
import '../models/coffee_v2_photo_slot.dart';
import '../services/coffee_v2_validation.dart';

class CoffeeV2StepView extends ConsumerStatefulWidget {
  const CoffeeV2StepView({
    super.key,
    required this.controller,
    required this.slot,
  });

  final CoffeeV2FlowController controller;
  final CoffeeV2PhotoSlot slot;

  @override
  ConsumerState<CoffeeV2StepView> createState() => _CoffeeV2StepViewState();
}

class _CoffeeV2StepViewState extends ConsumerState<CoffeeV2StepView> {
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
    final duplicateMessage = _duplicateMessageFor(controller.lastDuplicateIssue);
    final invalidMessage = controller.lastSelectionFailure != null
        ? CoffeeV2Copy.invalidPhotoMessage
        : null;
    final hint = _pickerError ?? invalidMessage ?? duplicateMessage;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: CoffeeReferenceTokens.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.s24),
          Text(
            CoffeeV2Copy.progressLabel(CoffeeV2Copy.stepNumber(slot)),
            textAlign: TextAlign.center,
            style: ReadingTypography.eyebrow(),
          ),
          SizedBox(height: AppSpacing.s12),
          Text(
            CoffeeV2Copy.titleFor(slot),
            textAlign: TextAlign.center,
            style: ReadingTypography.pageTitle(),
          ),
          SizedBox(height: AppSpacing.s12),
          Text(
            CoffeeV2Copy.instructionFor(slot),
            textAlign: TextAlign.center,
            style: ReadingTypography.secondary(),
          ),
          SizedBox(height: AppSpacing.s24),
          if (slot != CoffeeV2PhotoSlot.saucer)
            const SizedBox(height: 160, child: CoffeeCaptureCupGuide()),
          if (hint != null) ...[
            SizedBox(height: AppSpacing.s16),
            CoffeeCaptureHint(hint, attention: true),
          ],
          SizedBox(height: AppSpacing.s24),
          OraclyGoldButton(
            label: CoffeeV2Copy.actionTakePhoto,
            expanded: true,
            onPressed: _takePhoto,
          ),
          SizedBox(height: AppSpacing.s8),
          OraclyQuietLink(
            label: CoffeeV2Copy.actionPickGallery,
            onTap: _pickGallery,
          ),
          if (controller.replacingSlot != null) ...[
            SizedBox(height: AppSpacing.s8),
            OraclyQuietLink(
              label: 'Geri dön',
              onTap: controller.cancelReplacing,
            ),
          ],
          SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }

  String? _duplicateMessageFor(CoffeeV2ValidationIssue? issue) {
    return switch (issue) {
      CoffeeV2ValidationIssue.duplicatePrimarySecondary =>
        CoffeeV2Copy.duplicateSecondaryMessage,
      CoffeeV2ValidationIssue.duplicatePrimarySaucer =>
        CoffeeV2Copy.duplicateSaucerMessage,
      CoffeeV2ValidationIssue.duplicateSecondarySaucer =>
        CoffeeV2Copy.duplicateSaucerMessage,
      _ => null,
    };
  }
}
