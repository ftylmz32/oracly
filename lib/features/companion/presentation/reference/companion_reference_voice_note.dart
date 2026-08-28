/// Quiet note when SESLİ has no playable engine.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../copy/companion_copy.dart';

class CompanionReferenceVoiceNote extends StatelessWidget {
  const CompanionReferenceVoiceNote({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s4),
      child: Text(
        CompanionCopy.voiceOutputUnavailable,
        style: ReadingTypography.footnote(color: AppColors.textHint),
      ),
    );
  }
}
