/// Dream write / transcription review sheet.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../copy/dream_copy.dart';

class DreamReferenceWriteSheet extends StatefulWidget {
  const DreamReferenceWriteSheet({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  State<DreamReferenceWriteSheet> createState() =>
      _DreamReferenceWriteSheetState();
}

class _DreamReferenceWriteSheetState extends State<DreamReferenceWriteSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.text.trim().length;
    final maxSheet = MediaQuery.sizeOf(context).height * 0.92;

    return Padding(
      padding: EdgeInsets.only(
        bottom: AppLayout.sheetBottomInset(context),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.22),
            width: AppBorderWidth.hairline,
          ),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheet),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    DreamCopy.entryHeadline,
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: widget.controller,
                    maxLines: 7,
                    autofocus: true,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: DreamCopy.narrativeHint,
                      hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: AppColors.surface.withValues(alpha: 0.65),
                      border: _border(0.22),
                      enabledBorder: _border(0.22),
                      focusedBorder: _border(0.55),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    DreamCopy.narrativeHelper,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    DreamCopy.charCount(count),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  OraclyButton(
                    text: DreamCopy.beginAnalysis,
                    isExpanded: true,
                    onPressed: widget.onSubmit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(double goldAlpha) {
    return OutlineInputBorder(
      borderRadius: AppRadius.md,
      borderSide: BorderSide(color: AppColors.gold.withValues(alpha: goldAlpha)),
    );
  }
}
